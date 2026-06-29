import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constant/inifite_scroll_extent_threshold.dart';
import '../../constant/max_content_width.dart';
import '../../extension/scroll_controller_extension.dart';
import '../../i18n/strings.g.dart';
import '../../model/id.dart';
import '../../model/sound_settings.dart';
import '../../model/tab_settings.dart';
import '../../model/tab_type.dart';
import '../../provider/api/timeline_notes_after_note_notifier_provider.dart';
import '../../provider/api/timeline_notes_notifier_provider.dart';
import '../../provider/general_settings_notifier_provider.dart';
import '../../provider/misskey_sfx_notifier_provider.dart';
import '../../provider/streaming/timeline_stream_provider.dart';
import '../../provider/streaming/web_socket_channel_provider.dart';
import '../../provider/timeline_center_notifier_provider.dart';
import '../../provider/timeline_last_viewed_note_id_notifier_provider.dart';
import '../../provider/timeline_notes_queue_notifier_provider.dart';
import '../../provider/timeline_scroll_controller_provider.dart';
import '../../util/group_notes_into_threads.dart';
import '../../util/reload_timeline.dart';
import 'haptic_feedback_refresh_indicator.dart';
import 'notifications_list_view.dart';
import 'pagination_bottom_widget.dart';
import 'tab_reselect.dart';
import 'timeline_note.dart';

class TimelineListView extends HookConsumerWidget {
  const TimelineListView({
    super.key,
    required this.tabSettings,
    this.nested = false,
    this.focusPostForm,
    this.lastViewedAtKey,
    this.reselectSlot,
    this.topInset = 0.0,
  });

  final TabSettings tabSettings;
  final bool nested;
  final void Function()? focusPostForm;
  final Key? lastViewedAtKey;

  /// Height of a scrollable spacer prepended at the top of the list. Lets the
  /// content scroll out from under an overlaying, auto-hiding top bar without
  /// the notes being obscured when the bar is shown.
  final double topInset;

  /// When set, the list listens to [tabReselectProvider] for this slot and, on
  /// re-tap of its owning tab, scrolls to the top or refreshes if already there.
  final String? reselectSlot;

  /// Computes where to place the "new notes" divider in the reordered
  /// (threaded) display lists.
  ///
  /// The divider is placed between whole thread/standalone *units* (never
  /// inside a thread): above the newest unit whose leaf note has already been
  /// seen (`leaf.id <= lastViewedNoteId`), provided a not-yet-seen unit sits
  /// above it. The returned index matches the encoding consumed by the slivers:
  /// a positive value `i` puts the divider in the `nextNotes` sliver between
  /// display items `i - 1` and `i`, `0` puts it at the center pivot, and a
  /// negative value `-d` puts it in the `previousNotes` sliver above display
  /// item `d`. Returns `null` when no divider should be shown.
  @visibleForTesting
  int? computeNewNotesDividerIndex({
    required String? lastViewedNoteId,
    required List<DisplayNote> nextDisplay,
    required List<DisplayNote> previousDisplay,
  }) {
    if (lastViewedNoteId == null) {
      return null;
    }
    final combined = [...nextDisplay, ...previousDisplay];
    final nextLength = nextDisplay.length;
    int? unitStart;
    var sawNewUnit = false;
    for (var i = 0; i < combined.length; i++) {
      final displayNote = combined[i];
      if (!displayNote.connectTop) {
        unitStart = i;
      }
      if (!displayNote.connectBottom) {
        // End of the current unit; its leaf note is the newest in the unit.
        if (displayNote.note.id.compareTo(lastViewedNoteId) <= 0) {
          if (sawNewUnit && unitStart != null) {
            return nextLength - unitStart;
          }
          return null;
        }
        sawNewUnit = true;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = nested
        ? PrimaryScrollController.of(context)
        : ref.watch(timelineScrollControllerProvider(tabSettings));
    final refreshKey = useMemoized(
      () => GlobalKey<RefreshIndicatorState>(),
      [],
    );
    if (tabSettings.tabType == TabType.notifications) {
      // Delegates entirely to the notifications list, which handles its own
      // re-select behaviour.
      return NotificationsListView(
        account: tabSettings.account,
        controller: controller,
        reselectSlot: reselectSlot,
      );
    }
    listenTabReselect(
      ref,
      account: tabSettings.account,
      slot: reselectSlot,
      controller: controller,
      refreshKey: refreshKey,
    );
    // This is a center-anchored viewport, so the zero scroll offset sits at the
    // center pivot — on first load (no newer notes) the feed rests there with
    // the first note at the very top, which an overlaying top bar would cover. A
    // leading spacer sliver alone can't fix it (it lives above the pivot, off
    // screen at rest). Placing the zero offset `topInset` down — matching the
    // spacer's height — keeps the first note clear of the bar both at rest and
    // when scrolled to the very top.
    final anchor = topInset <= 0.0
        ? 0.0
        : (topInset / MediaQuery.sizeOf(context).height).clamp(0.0, 1.0);
    final lastViewedNoteId = ref.watch(
      timelineLastViewedNoteIdNotifierProvider(tabSettings),
    );
    final centerId = ref.watch(timelineCenterNotifierProvider(tabSettings));
    final centerKey = useMemoized(() => GlobalKey(), []);
    final hasUnread = useState(false);
    ref.listen(
      timelineNotesQueueNotifierProvider(
        tabSettings,
      ).select((notes) => notes.isNotEmpty),
      (_, next) => hasUnread.value = next,
    );
    final nextNotes = ref.watch(
      timelineNotesAfterNoteNotifierProvider(tabSettings, sinceId: centerId),
    );
    final hasNextNote = nextNotes.value?.items.isNotEmpty ?? false;
    final isLatestLoaded = nextNotes.value?.isLastLoaded ?? false;
    final untilId = centerId != null
        ? Id.tryParse(centerId)?.next().toString() ?? centerId
        : null;
    final previousNotes = ref.watch(
      timelineNotesNotifierProvider(tabSettings, untilId: untilId),
    );
    final partialPreviousNoteIds = {
      ...?previousNotes.value?.items.take(5).map((note) => note.id),
    };
    final hasPreviousNote = partialPreviousNoteIds.isNotEmpty;
    // Group reply chains present within each loaded segment into threads. The
    // two segments are grouped independently so neither crosses the center
    // pivot that keeps the scroll position stable.
    final nextDisplay = useMemoized(
      () => orderTimelineForThreads(nextNotes.value?.items ?? const []),
      [nextNotes.value?.items],
    );
    final previousDisplay = useMemoized(
      () => orderTimelineForThreads(previousNotes.value?.items ?? const []),
      [previousNotes.value?.items],
    );
    final (showGap, showPopup) = ref.watch(
      generalSettingsNotifierProvider.select(
        (settings) => (
          settings.showGapBetweenNotesInTimeline,
          settings.showPopupOnNewNote,
        ),
      ),
    );
    final newNoteDividerIndex = computeNewNotesDividerIndex(
      lastViewedNoteId: lastViewedNoteId,
      nextDisplay: nextDisplay,
      previousDisplay: previousDisplay,
    );
    final keepAnimation = useRef(true);
    final scrollingFrom = useRef<double?>(null);
    final scrollingTo = useRef<double?>(null);
    if (!tabSettings.disableStreaming) {
      useEffect(() {
        void callback() {
          if (controller.position.userScrollDirection ==
              ScrollDirection.reverse) {
            keepAnimation.value = false;
          } else if (controller.position.extentBefore == 0.0) {
            keepAnimation.value = true;
          } else if ((
                keepAnimation.value,
                scrollingFrom.value,
                scrollingTo.value,
                controller.position.minScrollExtent,
              )
              case (true, final from?, final to?, final minScrollExtent)
              when to != minScrollExtent && from > to) {
            final offset = controller.offset;
            final progress = (offset - from) / (to - from);
            scrollingFrom.value = offset;
            scrollingTo.value = minScrollExtent;
            if (progress < 0.7) {
              controller.animateTo(
                minScrollExtent,
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutQuint,
              );
            } else {
              final remaining = (minScrollExtent - offset).abs();
              controller.animateTo(
                minScrollExtent,
                duration:
                    const Duration(milliseconds: 300) *
                    min(remaining / 100.0, 2.0),
                curve: Curves.easeOut,
              );
            }
          }
        }

        if (isLatestLoaded) {
          controller.addListener(callback);
        }
        return () => controller.removeListener(callback);
      }, [tabSettings, isLatestLoaded]);
      if (isLatestLoaded) {
        ref.listen(timelineStreamProvider(tabSettings), (_, next) {
          if (next case AsyncData(value: final note)) {
            ref
                .read(
                  misskeySfxNotifierProvider(
                    note.user.username == tabSettings.account.username &&
                            note.user.host == null
                        ? OperationType.noteMy
                        : OperationType.note,
                  ).notifier,
                )
                .play()
                .ignore();
            if (keepAnimation.value && !hasUnread.value) {
              ref
                  .read(
                    timelineNotesAfterNoteNotifierProvider(
                      tabSettings,
                      sinceId: centerId,
                    ).notifier,
                  )
                  .addNote(note);
              if (controller.offset < 400.0) {
                ref
                    .read(
                      timelineLastViewedNoteIdNotifierProvider(
                        tabSettings,
                      ).notifier,
                    )
                    .save(note.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollingFrom.value = controller.offset;
                  final minScrollExtent = controller.position.minScrollExtent;
                  scrollingTo.value = minScrollExtent;
                  controller.animateTo(
                    minScrollExtent,
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutQuint,
                  );
                });
              } else {
                keepAnimation.value = false;
              }
            } else {
              ref
                  .read(
                    timelineNotesQueueNotifierProvider(tabSettings).notifier,
                  )
                  .add(note);
              keepAnimation.value = false;
            }
          }
        });
        ref.listen(
          webSocketChannelProvider(
            tabSettings.account,
          ).select((value) => value.error),
          (_, next) {
            if (next != null) {
              if (WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
                ref
                    .read(
                      timelineNotesAfterNoteNotifierProvider(
                        tabSettings,
                        sinceId: centerId,
                      ).notifier,
                    )
                    .pause();
              }
            }
          },
        );
      }
    }
    useEffect(() {
      void callback() {
        bool isAtTop = false;
        bool isAtBottom = false;
        if (controller.position.extentBefore <
                infiniteScrollExtentThreshold * 5 &&
            hasUnread.value) {
          final notes = ref
              .read(timelineNotesQueueNotifierProvider(tabSettings).notifier)
              .popMany(100);
          ref
              .read(
                timelineNotesAfterNoteNotifierProvider(
                  tabSettings,
                  sinceId: centerId,
                ).notifier,
              )
              .addNotes(notes);
        } else if (!isLatestLoaded) {
          if (controller.position.extentBefore <
              infiniteScrollExtentThreshold) {
            if (!isAtTop) {
              ref
                  .read(
                    timelineNotesAfterNoteNotifierProvider(
                      tabSettings,
                      sinceId: centerId,
                    ).notifier,
                  )
                  .loadMore(
                    sinceId:
                        nextNotes.value?.items.firstOrNull?.id ??
                        previousNotes.value?.items.firstOrNull?.id,
                  );
              isAtTop = true;
            }
          } else {
            isAtTop = false;
          }
        }
        if (controller.position.extentAfter < infiniteScrollExtentThreshold) {
          if (!isAtBottom) {
            ref
                .read(
                  timelineNotesNotifierProvider(
                    tabSettings,
                    untilId: untilId,
                  ).notifier,
                )
                .loadMore();
            isAtBottom = true;
          }
        } else {
          isAtBottom = false;
        }
      }

      if (ref.read(generalSettingsNotifierProvider).enableInfiniteScroll) {
        controller.addListener(callback);
      }
      return () => controller.removeListener(callback);
    }, [tabSettings, centerId, isLatestLoaded]);
    useEffect(() {
      void callback() {
        if (controller.position.extentBefore < infiniteScrollExtentThreshold) {
          final nextNotes = ref
              .read(
                timelineNotesAfterNoteNotifierProvider(
                  tabSettings,
                  sinceId: centerId,
                ),
              )
              .value
              ?.items;
          final latestNoteId = nextNotes?.firstOrNull?.id;
          if (latestNoteId != null &&
              (lastViewedNoteId == null ||
                  lastViewedNoteId.compareTo(latestNoteId) < 0)) {
            ref
                .read(
                  timelineLastViewedNoteIdNotifierProvider(
                    tabSettings,
                  ).notifier,
                )
                .save(latestNoteId);
          }
        }
      }

      if (tabSettings.keepPosition) {
        controller.addListener(callback);
      }
      return () => controller.removeListener(callback);
    }, [tabSettings, centerId]);

    return HapticFeedbackRefreshIndicator(
      indicatorKey: refreshKey,
      edgeOffset: topInset,
      onRefresh: () => reloadTimeline(ref, tabSettings),
      notificationPredicate: (_) => isLatestLoaded,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            controller: nested ? null : controller,
            center: centerKey,
            anchor: anchor,
            slivers: [
              if (topInset > 0.0)
                SliverToBoxAdapter(child: SizedBox(height: topInset)),
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    width: maxContentWidth,
                    child: PaginationBottomWidget(
                      paginationState: nextNotes,
                      loadMore: () {
                        if (hasUnread.value) {
                          final notes = ref
                              .read(
                                timelineNotesQueueNotifierProvider(
                                  tabSettings,
                                ).notifier,
                              )
                              .popMany(100);
                          ref
                              .read(
                                timelineNotesAfterNoteNotifierProvider(
                                  tabSettings,
                                  sinceId: centerId,
                                ).notifier,
                              )
                              .addNotes(notes);
                        } else {
                          ref
                              .read(
                                timelineNotesAfterNoteNotifierProvider(
                                  tabSettings,
                                  sinceId: centerId,
                                ).notifier,
                              )
                              .loadMore(
                                skipError: true,
                                sinceId:
                                    nextNotes.value?.items.firstOrNull?.id ??
                                    previousNotes.value?.items.firstOrNull?.id,
                              );
                        }
                      },
                      reversed: true,
                    ),
                  ),
                ),
              ),
              if (nextNotes.value != null)
                SliverList.separated(
                  itemBuilder: (context, index) {
                    final displayNote =
                        nextDisplay[nextDisplay.length - index - 1];
                    final note = displayNote.note;
                    final connectTop = displayNote.connectTop;
                    final connectBottom = displayNote.connectBottom;
                    final isTop = index == nextDisplay.length - 1;
                    final isBottom = index == 0 && !hasPreviousNote;
                    final (
                      isBelowNewNote,
                      isAboveNewNote,
                    ) = switch (newNoteDividerIndex) {
                      final i? => (index == i - 1, index == i),
                      _ => (false, false),
                    };

                    return Center(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: 8.0,
                          top: switch ((showGap, isTop, isBelowNewNote)) {
                            (true, true, _) => 4.0,
                            (false, true, _) => 8.0,
                            (false, false, true) => 4.0,
                            _ => 0.0,
                          },
                          right: 8.0,
                          bottom: switch ((showGap, isBottom, isAboveNewNote)) {
                            (true, true, _) => 4.0,
                            (false, true, _) => 8.0,
                            (false, false, true) => 4.0,
                            _ => 0.0,
                          },
                        ),
                        width: maxContentWidth,
                        child: TimelineNote(
                          key: ValueKey(note.id),
                          tabSettings: tabSettings,
                          noteId: note.id,
                          focusPostForm: focusPostForm,
                          connectTop: connectTop,
                          connectBottom: connectBottom,
                          margin: showGap
                              ? EdgeInsets.only(
                                  top: connectTop ? 0.0 : 4.0,
                                  bottom: connectBottom ? 0.0 : 4.0,
                                )
                              : EdgeInsets.zero,
                          borderRadius: showGap
                              ? BorderRadius.vertical(
                                  top: connectTop
                                      ? Radius.zero
                                      : const Radius.circular(8.0),
                                  bottom: connectBottom
                                      ? Radius.zero
                                      : const Radius.circular(8.0),
                                )
                              : BorderRadius.vertical(
                                  top: (isTop || isBelowNewNote) && !connectTop
                                      ? const Radius.circular(8.0)
                                      : Radius.zero,
                                  bottom:
                                      (isBottom || isAboveNewNote) &&
                                          !connectBottom
                                      ? const Radius.circular(8.0)
                                      : Radius.zero,
                                ),
                          hide: partialPreviousNoteIds.contains(note.id),
                          listViewKey: centerKey,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    if (showGap) {
                      return const SizedBox.shrink();
                    }
                    // No divider between two connected thread members.
                    if (nextDisplay[nextDisplay.length - index - 1]
                        .connectTop) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: maxContentWidth,
                        child:
                            newNoteDividerIndex != null &&
                                index == newNoteDividerIndex - 1
                            ? _NewNotesDivider(key: lastViewedAtKey)
                            : const Divider(height: 1.0),
                      ),
                    );
                  },
                  itemCount: nextDisplay.length,
                ),
              SliverToBoxAdapter(
                key: centerKey,
                child: hasNextNote && hasPreviousNote
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          width: maxContentWidth,
                          child: newNoteDividerIndex == 0
                              ? _NewNotesDivider(key: lastViewedAtKey)
                              : !showGap
                              ? const Divider(height: 1.0)
                              : null,
                        ),
                      )
                    : null,
              ),
              if (previousNotes.value != null)
                SliverList.separated(
                  itemBuilder: (context, index) {
                    final displayNote = previousDisplay[index];
                    final note = displayNote.note;
                    final connectTop = displayNote.connectTop;
                    final connectBottom = displayNote.connectBottom;
                    final isTop = index == 0 && !hasNextNote;
                    final isBottom = index == previousDisplay.length - 1;
                    final (
                      isBelowNewNote,
                      isAboveNewNote,
                    ) = switch (newNoteDividerIndex) {
                      final i? => (index == -i, index == -i - 1),
                      _ => (false, false),
                    };

                    return Center(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: 8.0,
                          top: switch ((showGap, isTop, isBelowNewNote)) {
                            (true, true, _) => 4.0,
                            (false, true, _) => 8.0,
                            (false, false, true) => 4.0,
                            _ => 0.0,
                          },
                          right: 8.0,
                          bottom: switch ((showGap, isBottom, isAboveNewNote)) {
                            (true, true, _) => 4.0,
                            (false, true, _) => 8.0,
                            (false, false, true) => 4.0,
                            _ => 0.0,
                          },
                        ),
                        width: maxContentWidth,
                        child: TimelineNote(
                          key: ValueKey(note.id),
                          tabSettings: tabSettings,
                          noteId: note.id,
                          focusPostForm: focusPostForm,
                          connectTop: connectTop,
                          connectBottom: connectBottom,
                          margin: showGap
                              ? EdgeInsets.only(
                                  top: connectTop ? 0.0 : 4.0,
                                  bottom: connectBottom ? 0.0 : 4.0,
                                )
                              : EdgeInsets.zero,
                          borderRadius: showGap
                              ? BorderRadius.vertical(
                                  top: connectTop
                                      ? Radius.zero
                                      : const Radius.circular(8.0),
                                  bottom: connectBottom
                                      ? Radius.zero
                                      : const Radius.circular(8.0),
                                )
                              : BorderRadius.vertical(
                                  top: (isTop || isBelowNewNote) && !connectTop
                                      ? const Radius.circular(8.0)
                                      : Radius.zero,
                                  bottom:
                                      (isBottom || isAboveNewNote) &&
                                          !connectBottom
                                      ? const Radius.circular(8.0)
                                      : Radius.zero,
                                ),
                          listViewKey: centerKey,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    if (showGap) {
                      return const SizedBox.shrink();
                    }
                    // No divider between two connected thread members.
                    if (previousDisplay[index + 1].connectTop) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: maxContentWidth,
                        child:
                            newNoteDividerIndex != null &&
                                index == -newNoteDividerIndex - 1
                            ? _NewNotesDivider(key: lastViewedAtKey)
                            : const Divider(height: 0.0),
                      ),
                    );
                  },
                  itemCount: previousDisplay.length,
                ),
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    width: maxContentWidth,
                    child: PaginationBottomWidget(
                      paginationState: previousNotes,
                      noItemsLabel: t.misskey.noNotes,
                      loadMore: () => ref
                          .read(
                            timelineNotesNotifierProvider(
                              tabSettings,
                              untilId: untilId,
                            ).notifier,
                          )
                          .loadMore(skipError: true),
                      height: 120.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasUnread.value && showPopup)
            Positioned(
              top: 8.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(
                    0.0,
                    DefaultTextStyle.of(context).style.fontSize! * 2.75,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final notes = ref
                      .read(
                        timelineNotesQueueNotifierProvider(
                          tabSettings,
                        ).notifier,
                      )
                      .popMany(100);
                  ref
                      .read(
                        timelineNotesAfterNoteNotifierProvider(
                          tabSettings,
                          sinceId: centerId,
                        ).notifier,
                      )
                      .addNotes(notes);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => controller.scrollToTop(),
                  );
                },
                child: Text(t.misskey.newNoteRecived),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewNotesDivider extends ConsumerWidget {
  const _NewNotesDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 2.0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            t.aria.newNotes,
            style: DefaultTextStyle.of(context).style
                .apply(color: color, fontSizeFactor: 0.9)
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 2.0)),
      ],
    );
  }
}

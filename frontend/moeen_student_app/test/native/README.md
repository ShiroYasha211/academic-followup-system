# Native Floating Review Checks

`ReviewTypesQaRunner.kt` exercises the production Android Views and service in
an isolated QA APK. It refuses to run under any application ID other than
`com.moeen.nativereviewqa`; it never uses a production account or API token.

The local, ignored harness is `build/verification/native-review-qa`. It supplies
an Android Activity, Flutter channel stubs, launcher resources, and the packaged
Cairo/Material fonts. Its manifest has no Internet permission. This harness is
not included in a fresh checkout; an equivalent isolated Android project is
required there. Never register the runner in the production manifest.

Copy the current `FloatingReviewService.kt`, `FloatingReviewCardView.kt`,
`FloatingReviewBubbleView.kt`, and `ReviewOverlayBridge.kt` from Android main
sources, plus this runner, into the harness's matching Kotlin package. Register:

```xml
<instrumentation
    android:name="com.mohammed.moeen.moeen_student_app.ReviewTypesQaRunner"
    android:targetPackage="com.moeen.nativereviewqa" />
```

Build the harness with the configured Android JDK and SDK, install its debug APK
on an unlocked device, and grant overlay/notification permissions to the QA app
only. Run:

```text
adb shell am instrument -w -r com.moeen.nativereviewqa/com.mohammed.moeen.moeen_student_app.ReviewTypesQaRunner
```

Success reports seven passed scenarios and `INSTRUMENTATION_CODE: -1`:

- Mixed-type bubble count excludes invalid, duplicate, and future entries.
- Reveal and close do not record progress; grading before reveal is ignored.
- QA saves a medium rating and occurrence once despite repeated taps.
- Next opens a flashcard and saves its chosen hard rating.
- Existing MCQ selection completes the mixed queue without duplicate progress.
- Foreground/exam suppression applies to the newly supported types.
- Long Arabic answers scroll at 1.6 text scale with intact rating labels.

The runner writes `types-report.txt`, `qa-answer.png`, and `long-answer.png` to
the QA application's external files directory. Inspect the images, then uninstall
the QA app. These checks cover local native behavior, not production network
delivery or other Android vendors.

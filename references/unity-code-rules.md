## Code rules (Unity)

- **Async uses UniTask.** Write asynchronous work (waiting a frame or time, tweens, loading assets, ...) with `UniTask` /
  `UniTask<T>`. Do not use `Task`, coroutines (`IEnumerator` + `StartCoroutine`) or `async void`. Use `UniTaskVoid` only for
  fire-and-forget work, started with `.Forget()`.
- **Events use UniRx instead of `Action`.** Where possible, do not declare `System.Action` / `event` for event streams or values
  that change over time. Use `Subject<T>` / `IObservable<T>` for events and `ReactiveProperty<T>` / `ReactiveCommand` for state,
  and subscribe with `.Subscribe(...).AddTo(Disposables)` so the subscription is disposed in time. Keep `Action` where UniRx does
  not fit: a one-off callback passed into a method, or a third-party API that requires a delegate type.

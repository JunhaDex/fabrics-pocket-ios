# fabrics-pocket-ios

## 로컬 웹앱을 앱에서 띄우기

Debug 구성은 `http://localhost:3000`을 시작 화면으로 연다.

1. 웹앱 dev 서버를 개발 머신의 `localhost:3000`에서 실행한다.
   다른 주소를 띄우려면 `Config/Local.xcconfig`(커밋 제외)를 만들어 `POCKET_START_URL`을
   덮어쓴다. xcconfig에서 `//`는 주석이므로 `http:/$()/localhost:5173`처럼 쓴다.
2. Xcode에서 Debug 구성으로 시뮬레이터에 실행한다.
   시뮬레이터는 개발 머신의 `localhost`를 그대로 쓰므로 추가 설정이 없다.

- 실기기에서는 개발 머신의 `localhost`에 접근할 수 없다. 시뮬레이터로 확인한다.
- 평문 HTTP는 Debug 구성에서만 허용되며 `127.0.0.1` 같은 IP 주소에는 적용되지
  않는다. 호스트명 `localhost`를 쓴다.
- 웹 콘솔은 Safari의 개발자용 메뉴(Web Inspector)에서 볼 수 있다. Debug 구성에만 열려 있다.

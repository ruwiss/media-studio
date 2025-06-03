Yapılacak olan uygulama bir masaüstü uygulamasıdır.
Hafif, minimal bir uygulama olmalıdır.
Dosya yapısı projeye uygun şekilde kurulmalıdır ve projeyi kalabalıklaştırmaktan da kaçınılmalıdır.
Uygulamanın amacı, video düzenleyiciler için yardımcı bir araç olmaktır.

Ses Oluşturucu, Resim, GIF, Video bulucu özelliklere sahip olacaktır.

API'larımızı eklemek için bir ayarlar kısmı olacak ve yedek API'lar da ekleyebileceğiz.

Ses Oluşturucu olarak Elevenlabs API kullanacağız. Limit gösterme özelliği olacak.
Elevenlabs'de geçerli ses id'miz bu olacak: "29vD33N1CtxCmqQRPOHJ" ve Multilangual özellik olacak.

Resim ve GIF bulucu için Yandex Görseller API ve Pixabay API kullanacağız.
https://pixabay.com/api/docs/#api_search_images
https://yandex.cloud/en/docs/search-api/concepts/pic-search
(yandex kısmında sadece png ve gif olarak arama yapacabileceğiz)

Oluşturulan / Seçilen Ses, GIF, Resim, Videolar locale indirilebilecek ve eğer indirilen medyayı tutup sürüklersem oraya taşınacak. Taşıma amacımız medyayı video editor'e kolayca eklemektir.

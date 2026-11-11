////////////////////////////////////////////////////////////////////////////////
// Client procedures and functions that control system settings.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// The settings are searched for in the administration panels during the global search.
//
// Parameters:
//  SearchString          - String - the entered string in the global search field.
//  GlobalSearchPlan - GlobalSearchPlan - types of search.
//
Procedure OnGlobalSearch(SearchString, GlobalSearchPlan) Export
	
	If SearchStringMeetsRequirements(SearchString) Then
		
		GlobalSearchPlan.Add("FillInResultOfGlobalSearchForSettingsByAccountingSections",
			"SystemSettings",
			True,
			True);
		GlobalSearchPlan.Add("FillInResultOfGlobalSearchForAccountingPolicies",
			"AccountingPoliciesTaxSettings",
			True,
			True);
			
		SettingsSearchPlan = GlobalSearchPlan.Find("FillInResultOfGlobalSettingsSearch",
			"SystemSettingsClient");
		If SettingsSearchPlan = Undefined Then
			GlobalSearchPlan.Add("AddStartSystemSettingsSearch", 
				"SystemSettingsClient",
				False,
				False,
				94);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Complements the global search result with a suggestion to search by settings.
// 
// Parameters:
//  SearchString                - String - search bar. 
//  GlobalSearchResults - GlobalSearchResult - contains search results.
//  AdditionalParameters     - Structure - advanced setting.
//
Procedure AddStartSystemSettingsSearch(SearchString, GlobalSearchResults, AdditionalParameters) Export
	SearchTitle = NStr("vi = 'Tìm kiếm trong tùy chỉnh...';
						|ru = 'Найти в настройках...';
						|en = 'Find in the settings...'; fa = 'Find in the settings...';
						|it = 'Find in the settings...';
						|pl = 'Find in the settings...';
						|tr = 'Ayarlarda bul...'");
	GlobalSearchResults.Add(SearchString, SearchTitle, PictureLib.DataSearch,
		"StartingSystemSettingsSearch", "");
EndProcedure

// Fills in the global search result.
// 
// Parameters:
//  SearchString                - String - search bar. 
//  GlobalSearchResults - GlobalSearchResult - contains search results.
//  AdditionalParameters     - Structure - advanced setting.
//
Procedure FillInResultOfGlobalSettingsSearch(SearchString, GlobalSearchResults, AdditionalParameters) Export

	SearchResults = GlobalSettingsSearchResults(SearchString);

	If SearchResults = Undefined Then
		Return;
	EndIf;

	For Each SearchResult In SearchResults Do
		GlobalSearchResults.Add(SearchResult.Value, SearchResult.Presentation, SearchResult.Picture,
			"SearchForSystemSettings", SearchResult.ActionDetails);
	EndDo;
	
	GlobalSearchPlan = GlobalSearch.GetPlan();
	SettingsSearchPlan = GlobalSearchPlan.Find("FillInResultOfGlobalSettingsSearch",
		"SystemSettingsClient");
	If SettingsSearchPlan <> Undefined Then
		GlobalSearchPlan.Delete(SettingsSearchPlan);
		GlobalSearch.SetPlan(GlobalSearchPlan);
	EndIf;

EndProcedure

// Performed when selecting the result of a global search for system settings.
//
// Parameters:
//  ResultItem    - GlobalSearchResultItem - the selected search result string.
//  StandardProcessing - Boolean - default processing flag.
//
Procedure OnGlobalSearchResultChoice(ResultItem, StandardProcessing) Export
	
	If ResultItem.SearchType = "SearchForSystemSettings" Then
		ClearMessages();
		StandardProcessing = False;
		
		//@skip-check use-non-recommended-method
		Form = GetForm(ResultItem.Description, Undefined);
		FoundItem = Form.Items.Find(ResultItem.Value);
		
		If Form <> Undefined And TypeOf(Form) = Type("ClientApplicationForm") Then
			Form.Open();
			Form.CurrentItem = FoundItem;
		EndIf;
	ElsIf ResultItem.SearchType = "StartingSystemSettingsSearch"
		And ValueIsFilled(ResultItem.Value) Then
		
		ClearMessages();
		StandardProcessing = False;
		
		GlobalSearchPlan = GlobalSearch.GetPlan();
		GlobalSearchPlan.Add("FillInResultOfGlobalSettingsSearch",
			"SystemSettingsClient",
			False,
			False);
		GlobalSearch.SetPlan(GlobalSearchPlan);
		
		GlobalSearch.BeginSearch(ResultItem.Value);
	EndIf;
	
EndProcedure

// Additional settings search index.
// 
// Returns:
//  Map of KeyAndValue - Additional Settings Search Index:
//		*Key - String - element name
//		*Value - String - search string
Function AdditionalSettingsSearchIndex() Export
	
	SearchIndex = New Map();
	
#Region Purchases
	FormName = "DataProcessor.TMAdministrationPanel.Form.Purchases";
	
	ElementsKeywords = New Map();
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingCommercialTermsAndConditionsOfPurchaseDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện thương mại';
			|ru = 'Ответственные за согласование коммерческих условий';
			|en = 'Persons responsible for commercial conditions'; fa = 'اشخاص مسئول شرایط تجاری';
			|it = 'Responsabili per il coordinamento delle condizioni commerciali ';
			|pl = 'Odpowiedzialni za uzgadnianie warunków komercyjnych';
			|tr = 'Ticari koşulları müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingTheLogisticsConditionsOfThePurchaseDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện logistic';
			|ru = 'Ответственные за согласование логистических условий';
			|en = 'Persons responsible for logistic conditions'; fa = 'اشخاص مسئول شرایط لجستیکی';
			|it = 'Responsabili per il coordinamento delle condizioni logistiche';
			|pl = 'Odpowiedzialni za uzgadnianie warunków logistycznych';
			|tr = 'Lojistik koşullarını müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingTheFinancialTermsOfThePurchaseDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện tài chính';
			|ru = 'Ответственные за согласование финансовых условий';
			|en = 'Persons responsible for financial conditions'; fa = 'اشخاص مسئول شرایط مالی';
			|it = 'Responsabili per il coordinamento delle condizioni commerciali';
			|pl = 'Odpowiedzialni za uzgadnianie warunków finansowych';
			|tr = 'Finansal koşullarını müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingThePriceConditionsOfPurchaseDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện giá';
			|ru = 'Ответственные за согласование ценовых условий';
			|en = 'Persons responsible for price conditions'; fa = 'اشخاص مسئول شرایط قیمت';
			|it = 'Responsabili per il coordinamento delle condizioni di prezzo';
			|pl = 'Odpowiedzialni za uzgadnianie warunków cenowych';
			|tr = 'Fiyat koşullarının onayından sorumlular'"));
	ElementsKeywords.Insert("EnableVersioningOfPurchaseDocuments",
		NStr("vi = 'Ghi nhận thay đổi và lưu trữ các phiên bản của chứng từ Đặt hàng đặt nhà cung cấp';
			|ru = 'Регистрация изменений и хранение версий документа Заказ поставщику';
			|en = 'Register changes and store the Purchase order document versions.'; fa = 'Register changes and store the Purchase order document versions.';
			|it = 'Register changes and store the Purchase order document versions.';
			|pl = 'Register changes and store the Purchase order document versions.';
			|tr = 'Değişikliklerin kaydı ve Satın alma siparişi belgesinin sürümlerinin saklanması'"));
	
	SearchIndex.Insert(FormName, ElementsKeywords);
	ElementsKeywords.Clear();
#EndRegion
	
#Region Sales
	FormName = "DataProcessor.TMAdministrationPanel.Form.Sales";
	
	ElementsKeywords = New Map();
	ElementsKeywords.Insert("AssignPersonsResponsibleForReturnRequestApproval",
		NStr("vi = 'Chịu trách nhiệm thống nhất giấy đề nghị trả hàng';
			|ru = 'Ответственные за согласование заявок на возврат';
			|en = 'Persons responsible for return requests'; fa = 'اشخاص مسئول درخواست‌های مرجوعی';
			|it = 'Responsabili per il coordinamento delle richieste di reso';
			|pl = 'Odpowiedzialni za uzgodnienie zgłoszeń do zwrotu';
			|tr = 'İade taleplerinin onaylanmasından sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingCommercialTermsAndConditionsOfSaleDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện thương mại';
			|ru = 'Ответственные за согласование коммерческих условий';
			|en = 'Persons responsible for commercial conditions'; fa = 'اشخاص مسئول شرایط تجاری';
			|it = 'Responsabili per il coordinamento delle condizioni commerciali ';
			|pl = 'Odpowiedzialni za uzgadnianie warunków komercyjnych';
			|tr = 'Ticari koşulları müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingTheLogisticsConditionsOfSalesDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện logistic';
			|ru = 'Ответственные за согласование логистических условий';
			|en = 'Persons responsible for logistic conditions'; fa = 'اشخاص مسئول شرایط لجستیکی';
			|it = 'Responsabili per il coordinamento delle condizioni logistiche';
			|pl = 'Odpowiedzialni za uzgadnianie warunków logistycznych';
			|tr = 'Lojistik koşullarını müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingTheFinancialTermsOfSalesDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện tài chính';
			|ru = 'Ответственные за согласование финансовых условий';
			|en = 'Persons responsible for financial conditions'; fa = 'اشخاص مسئول شرایط مالی';
			|it = 'Responsabili per il coordinamento delle condizioni commerciali';
			|pl = 'Odpowiedzialni za uzgadnianie warunków finansowych';
			|tr = 'Finansal koşullarını müzakere etmekten sorumlu'"));
	ElementsKeywords.Insert("AssignThoseResponsibleForApprovingThePriceConditionsOfSalesDocuments",
		NStr("vi = 'Chịu trách nhiệm thống nhất điều kiện giá';
			|ru = 'Ответственные за согласование ценовых условий';
			|en = 'Persons responsible for price conditions'; fa = 'اشخاص مسئول شرایط قیمت';
			|it = 'Responsabili per il coordinamento delle condizioni di prezzo';
			|pl = 'Odpowiedzialni za uzgadnianie warunków cenowych';
			|tr = 'Fiyat koşullarının onayından sorumlular'"));
	
	SearchIndex.Insert(FormName, ElementsKeywords);
	ElementsKeywords.Clear();
#EndRegion

#Region PersonalSettings
	FormName = "CommonForm.PersonalSettings";
	
	ElementsKeywords = New Map();
	ElementsKeywords.Insert("UserInfo",
		NStr("vi = 'Thông tin về người sử dụng';
			|ru = 'Сведения о пользователе';
			|en = 'User details'; fa = 'جزئیات کاربر';
			|it = 'Informazioni dell''utente';
			|pl = 'Informacje o użytkowniku';
			|tr = 'Kullanıcı bilgileri'"));
	ElementsKeywords.Insert("ProxyServerCustomSettings",
		NStr("vi = 'Tùy chỉnh truy cập đến Internet';
			|ru = 'Настройка доступа к Интернету';
			|en = 'Internet connection settings'; fa = 'تنظیمات اتصال اینترنت';
			|it = 'Impostare l''accesso a Internet';
			|pl = 'Ustawienie dostępu do Internetu';
			|tr = 'İnternet erişimi ayarı'"));
	ElementsKeywords.Insert("EmailOperationSettings",
		NStr("vi = 'Tùy chỉnh làm việc với thư';
			|ru = 'Настройки работы с почтой';
			|en = 'Account settings'; fa = 'تنظیمات حساب';
			|it = 'Impostazioni di uso della posta';
			|pl = 'Ustawienia pracy z pocztą';
			|tr = 'Hesap ayarları'"));
	ElementsKeywords.Insert("ReminderSettings",
		NStr("vi = 'Tùy chỉnh nhắc việc';
			|ru = 'Настройки напоминаний';
			|en = 'Reminder settings'; fa = 'تنظیمات یادآوری';
			|it = 'Reminder settings';
			|pl = 'Reminder settings';
			|tr = 'Hatırlatma ayarları'"));
	ElementsKeywords.Insert("InstallFileSystemExtensionAtClient",
		NStr("vi = 'Cài đặt phần mở rộng để làm việc với tệp';
			|ru = 'Установить расширение работы с файлами';
			|en = 'Install 1C:Enterprise Extension'; fa = 'نصب افزونه 1C:Enterprise';
			|it = 'Installare l''estensione di lavoro con file';
			|pl = 'Zainstaluj rozszerzenie do pracy z plikami';
			|tr = 'Dosya yönetimi uzantısını yükle'"));
	ElementsKeywords.Insert("UpdateSystemParameters",
		NStr("vi = 'Cập nhật tham số hệ thống';
			|ru = 'Обновить параметры системы';
			|en = 'Update system parameters'; fa = 'به‌روزرسانی پارامترهای سیستم';
			|it = 'Aggiornare i parametri del sistema';
			|pl = 'Zaktualizuj parametry systemu';
			|tr = 'Sistem parametrelerini güncelle'"));
	ElementsKeywords.Insert("AskConfirmationOnExit",
		NStr("vi = 'Yêu cầu xác nhận khi kết thúc ứng dụng';
			|ru = 'Запрашивать подтверждение при завершении приложения';
			|en = 'Ask confirmation on exit'; fa = 'درخواست تأیید هنگام خروج';
			|it = 'Ask confirmation on exit';
			|pl = 'Ask confirmation on exit';
			|tr = 'Uygulama sonlandırıldığında onay isteyin'"));
	ElementsKeywords.Insert("ShowInstalledApplicationUpdatesWarning",
		NStr("vi = 'Hiển thị cảnh báo về các bản cập nhật đã cài đặt của ứng dụng';
			|ru = 'Показывать предупреждение об установленных обновлениях приложения';
			|en = 'Show warning about installed application updates'; fa = 'نمایش هشدار درباره به‌روزرسانی‌های نصب‌شده برنامه';
			|it = 'Show warning about installed application updates';
			|pl = 'Show warning about installed application updates';
			|tr = 'Yüklü uygulama güncellemeleri hakkında bir uyarı gösterme'"));
	ElementsKeywords.Insert("ShowLockedFilesOnExit",
		NStr("vi = 'Hiển thị tệp bị chiếm khi kết thúc công việc';
			|ru = 'Показывать занятые файлы при завершении работы';
			|en = 'Show locked files before exit'; fa = 'نمایش فایل‌های قفل‌شده پیش از خروج';
			|it = 'Visualizzare i file occupati al momento di chiusura della sessione';
			|pl = 'Pokazuj zajęte pliki przy zakończeniu pracy';
			|tr = 'Çıkışta kilitli dosyaları göster'"));
	ElementsKeywords.Insert("ShowFileNotModifiedFlag",
		NStr("vi = 'Hiển thị thông tin mà còn chưa thay đổi tệp';
			|ru = 'Показывать информацию, что файл не был изменен';
			|en = 'Notify that files have not been modified'; fa = 'Notify that files have not been modified';
			|it = 'Visualizzare l''informazione che il file non è stato modificato';
			|pl = 'Pokazywać informacje, ze plik nie został zmieniony';
			|tr = 'Dosyanın değiştirilmediği bilgisini göster'"));
	ElementsKeywords.Insert("WorkingDirectorySettings",
		NStr("vi = 'Thư mục làm việc chính';
			|ru = 'Основной рабочий каталог';
			|en = 'Main working directory'; fa = 'پوشه کاری اصلی';
			|it = 'Main working directory';
			|pl = 'Main working directory';
			|tr = 'Temel çalışma dizini'"));
	ElementsKeywords.Insert("ScanningSettings",
		NStr("vi = 'Tùy chỉnh máy quét ảnh';
			|ru = 'Настройка сканирования';
			|en = 'Scanner settings'; fa = 'تنظیمات اسکنر';
			|it = 'Impostazioni scansione';
			|pl = 'Konfiguracja skanowania';
			|tr = 'Tarama ayarı'"));
	ElementsKeywords.Insert("ConfigureDS",
		NStr("vi = 'Tùy chỉnh chữ ký điện tử...';
			|ru = 'Настройка ЭЦП';
			|en = 'Configure digital signature'; fa = 'پیکربندی امضای دیجیتال';
			|it = 'Impostazione firma elettronica digitale';
			|pl = 'Konfiguracja podpisu elektronicznego';
			|tr = 'Dijital imza ayarı'"));
	ElementsKeywords.Insert("InstallCryptoExtension",
		NStr("vi = 'Cài đặt phần mở rộng để làm việc với mã hóa';
			|ru = 'Установить расширение работы с криптографией';
			|en = 'Install crypto extension'; fa = 'نصب افزونه رمزنگاری';
			|it = 'Installare l''estensione per lavorare con la crittografia';
			|pl = 'Zainstaluj rozszerzenie do pracy z kryptografią';
			|tr = 'Şifreleme uzantısı yükle'"));
	ElementsKeywords.Insert("SetActionOnChoosePrintFormTemplate",
		NStr("vi = 'Chỉ ra thao tác khi chọn khuôn in của mẫu in...';
			|ru = 'Действие при выборе макета печатной формы';
			|en = 'Action when selecting the print form template'; fa = 'اقدام هنگام انتخاب الگوی فرم چاپی';
			|it = 'Azione durante la scelta del layout dei moduli di stampa';
			|pl = 'Czynności podczas wyboru makiety formularza wydruku';
			|tr = 'Yazdırma formu şablonu seçilirken eylem'"));
	ElementsKeywords.Insert("RequestConfirmationWhenPrintingASetOfDocuments",
		NStr("vi = 'Yêu cầu xác nhận khi in nhanh bộ chứng từ';
			|ru = 'Запрашивать подтверждение при быстрой печати комплекта документов';
			|en = 'Request confirmation on quick document set printing'; fa = 'درخواست تأیید هنگام چاپ سریع مجموعه اسناد';
			|it = 'Richiedere la conferma per la stampa rapida di documenti';
			|pl = 'Żądaj potwierdzenia przy szybkim drukowaniu zestawu dokumentów';
			|tr = 'Belge setini hızlı yazdırırken onay iste'"));
	ElementsKeywords.Insert("ConfigureAuthorizationParametersIn1WithDocumentFlow",
		NStr("vi = 'Thiết lập tham số đăng nhập 1C:Quản lý văn bản (ECM)...';
			|ru = 'Параметры авторизации в 1С:Документооборот';
			|en = '1C:Document Management authorization parameters'; fa = 'پارامترهای احراز مجوز 1C:Document Management';
			|it = 'Parametri di autorizzazione nel 1C:Flusso di documenti';
			|pl = 'Parametry uwierzytelniania w 1C:Obieg dokumentów';
			|tr = '1C:Document Management üzerinde kimlik doğrulama parametreleri'"));
	ElementsKeywords.Insert("DisableControlOfProductBalances",
		NStr("vi = 'Ngắt kiểm soát số dư (trong phiên làm việc)';
			|ru = 'Отключить контроль остатков (на время сеанса)';
			|en = 'Disable stock balance control (for the session time)'; fa = 'غیرفعال کردن کنترل مانده موجودی (برای مدت جلسه)';
			|it = 'Disabilitare il controllo delle rimanenze (per la durata della sessione)';
			|pl = 'Wyłącz kontrolę pozostałości (na czas sesji)';
			|tr = 'Bakiye kontrolünü devre dışı bırak (oturum süresince)'"));
	ElementsKeywords.Insert("DisableMonitoringOfGoodsReservesOnOrders",
		NStr("vi = 'Ngắt kiểm soát dự phòng (vào thời gian của phiên)';
			|ru = 'Отключить контроль резервов (на время сеанса)';
			|en = 'Disable reserve control (for the session time)'; fa = 'غیرفعال کردن کنترل رزرو (برای مدت جلسه)';
			|it = 'Отключить контроль резервов (на время сеанса)';
			|pl = 'Disable reserve control (for the session time)';
			|tr = 'Rezerv kontrolünü devre dışı bırak (oturum süresince)'"));
	ElementsKeywords.Insert("TurnOffBalanceControlOfCustomersRebates",
		NStr("vi = 'Tắt sử dụng kiểm soát số dư thưởng lũy kế cho khách hàng (trong phiên làm việc)';
			|ru = 'Отключить контроль остатков ретро-бонусов клиентов (на время сеанса)';
			|en = 'Disable customer rebate balance check (for the session time)'; fa = 'غیرفعال کردن بررسی مانده تخفیف برگشتی مشتری (برای مدت جلسه)';
			|it = 'Отключить контроль остатков ретро-бонусов клиентов (на время сеанса)';
			|pl = 'Disable customer rebate balance check (for the session time)';
			|tr = 'Müşteri retro bonusu bakiyelerinin kontrolünü devre dışı bırak (oturum esnasında)'"));
	ElementsKeywords.Insert("FillInDocumentAttributesUsingStatisticalData",
		NStr("vi = 'Điền thông tin chi tiết của chứng từ về số liệu thống kê';
			|ru = 'Заполнять реквизиты документов по статистике';
			|en = 'Fill document attributes using statistical data'; fa = 'پرکردن ویژگی‌های سند با استفاده از داده‌های آماری';
			|it = 'Compilare i requisiti dei documenti in base alla statistica';
			|pl = 'Wypełniaj atrybuty dokumentów zgodnie ze statystyką';
			|tr = 'İstatistiklere göre belgelerin öznitelikleri doldur'"));
	ElementsKeywords.Insert("PersonalSettingsChangeSignature",
		NStr("vi = 'Tùy chỉnh thay đổi chữ ký trong các chứng từ';
			|ru = 'Настройки смены подписи в документах';
			|en = 'Settings for changing signature in documents'; fa = 'تنظیمات تغییر امضا در اسناد';
			|it = 'Settings for changing signature in documents';
			|pl = 'Settings for changing signature in documents';
			|tr = 'Belgelerdeki imzaları değiştirme ayarları'"));
	ElementsKeywords.Insert("ClearSettingsForSigningEDSPersonnelEDI",
		NStr("vi = 'Xóa tùy chỉnh ký chữ ký điện tử';
			|ru = 'Очистить настройки подписания ЭЦП';
			|en = 'Clear digital signature settings'; fa = 'پاک کردن تنظیمات امضای دیجیتال';
			|it = 'Cancellare le impostazioni di firma elettronica digitale';
			|pl = 'Wyczyść ustawienia podpisania podpisu elektronicznego';
			|tr = 'Dİ imzalama ayarlarını temizle'"));
	ElementsKeywords.Insert("NotificationsSettings",
		NStr("vi = 'Cài đặt cảnh báo';
			|ru = 'Настройки оповещений';
			|en = 'Notification settings'; fa = 'تنظیمات اعلان';
			|it = 'Impostazioni notifiche';
			|pl = 'Ustawienia powiadomień';
			|tr = 'Bildirim ayarları'"));
	SearchIndex.Insert(FormName, ElementsKeywords);
	ElementsKeywords.Clear();
#EndRegion

	SystemSettingsClientLocalization.AddSettingsSearchIndex(SearchIndex);
	Return SearchIndex
	
EndFunction

// Constructor of the form property.
// 
// Parameters:
//  FormName - Undefined, String - form name
// 
// Returns:
//  Structure - Form Property Constructor:
// * NameOfFormAsString - String, FormattedString - 
// * Items - Array of See FormElementConstructor
Function FormPropertyConstructor(FormName = Undefined) Export
	
	Result = New Structure("NameOfFormAsString, Items", "", New Array);
	Return Result
	
EndFunction

// Form element constructor.
// 
// Returns:
//  Structure - Form Element Constructor:
// * Name - String - 
// * Title - String - 
// * ToolTip - String - 
// * ExtendedTooltip - String - 
// * Type - Undefined, Type - 
Function FormElementConstructor() Export
	
	Result = New Structure();
	Result.Insert("Name", "");
	Result.Insert("Title", "");
	Result.Insert("ToolTip", "");
	Result.Insert("ExtendedTooltip", "");
	Result.Insert("Type", Undefined);
	
	Return Result
	
EndFunction

// Parameters:
//  Items - Array of See FormElementConstructor
//  Item - FormField, FormDecoration, FormTable, FormButton, FormGroup - Item
//  ColorExplanatoryText - Color - Color Explanatory Text
Procedure AddFormItem(Items, Item, ColorExplanatoryText) Export
	If TypeOf(Item) = Type("FormDecoration")
		Or TypeOf(Item) = Type("FormField")
		Or TypeOf(Item) = Type("FormButton") Then
		
		If ElementIsVisible(Item) Then
			
			FormItem = FormElementConstructor();
			FormItem.Name = Item.Name;
			FormItem.Title = Item.Title;
			FormItem.Type = TypeOf(Item);
			
			//@skip-check empty-except-statement
			Try
				FormItem.ToolTip = New FormattedString(Item.ToolTip,,ColorExplanatoryText);
			Except
			EndTry;
			
			//@skip-check empty-except-statement
			Try
				FormItem.ExtendedTooltip = New FormattedString(Item.ExtendedTooltip.Title,,ColorExplanatoryText);
			Except
			EndTry;
			
			Items.Add(FormItem);
		EndIf;
		
	EndIf;
EndProcedure

// Checks form elements for a match with the search string.
// 
// Parameters:
//  SearchString - String - search string.
//  FormItems - FormItems - collection of form elements.
//  FormName - String, FormattedString - The name of the form.
//  SearchIndex - Map of KeyAndValue - cache of search indexes for form elements.
//
// Returns:
//  Array of See NewResultDescription
//
Function FindItemsByRow(SearchString, FormItems, FormName, SearchIndex) Export
	Result = New Array;
	
	If IsBlankString(SearchString) Then
		Return Result;
	EndIf;
	
	For Each FormItem In FormItems Do
		FoundRow = FindLine(FormItem, SearchString, SearchIndex);
		If FoundRow <> Undefined Then
			AddSearchResult(Result, FormItem, FoundRow, FormName);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// New description of the result.
// 
// Parameters:
//  FormItem - FormGroup, FormTable, FormField, FormButton, FormDecoration - Form element
//  FoundRow - FormattedString, Undefined - Found string
//  FormName - String, FormattedString - form name
// 
// Returns:
//  Structure - New Result Description:
// * FormItem - FormGroup, FormTable, FormField, FormButton, FormDecoration - 
// * FoundRow - FormattedString, Undefined - 
// * FormName - String, FormattedString - 
Function NewResultDescription(FormItem, FoundRow, FormName) Export
	
	Result = New Structure();
	Result.Insert("FormItem", FormItem);
	Result.Insert("FoundRow", FoundRow);
	Result.Insert("FormName", FormName);
	Return Result
	
EndFunction

#EndRegion

#Region Private

Function GlobalSettingsSearchResults(SearchString)
	SearchResults = New Array;
	
	For Each FormName In SearchForms() Do
		FormSearchResult(SearchString, FormName, SearchResults);
	EndDo;
	
	Return SearchResults;
	
EndFunction

Procedure FormSearchResult(Val SearchString, FormName, SearchResults)
	
	FoundItems1 = SystemSettingsClientCached.FormElementsByLine(SearchString, FormName);
	For Each FoundItem In FoundItems1 Do
		
		FormItem = FoundItem.FormItem; // FormField, FormDecoration, FormButton - 
		
		SearchResult = SystemSettingsClientServer.NewGlobalSearchResult();
		SearchResult.Value = FormItem.Name;
		
		RowsArray = New Array;
		RowsArray.Add(FoundItem.FoundRow);
		RowsArray.Add(Chars.LF);
		RowsArray.Add(FoundItem.FormName);
		
		SearchResult.Presentation = New FormattedString(RowsArray);
		
		If FormItem.Type = Type("FormDecoration") Then
			SearchResult.Picture = PictureLib.Information;
		Else
			SearchResult.Picture = PictureLib.Setting;
		EndIf;
		
		SearchResult.ActionDetails = FormName;
		
		SearchResults.Add(SearchResult);
		
	EndDo;
	
EndProcedure

Procedure AddSearchResult(SearchResults, FormItem, FoundRow, FormName)
	
	Result = NewResultDescription(FormItem, FoundRow, FormName);
	SearchResults.Add(Result);
	
EndProcedure

Function FindLine(FormItem, SearchString, SearchIndex)
	
	Result = Undefined;
	SearchIndexElement = Undefined;
	
	If ValueIsFilled(SearchIndex) Then
		SearchIndexElement = SearchIndex.Get(FormItem.Name);
	EndIf;
	
	RowsArray = New Array;
	RowFound = False;
	If ValueIsFilled(FormItem.Title) Then
		FoundRow = StrFindAndHighlightByAppearance(FormItem.Title, SearchString);
		AddStringToArrayOfStrings(RowsArray, FoundRow, FormItem.Title);
		RowFound = RowFound Or FoundRow <> Undefined;
	ElsIf FormItem.Type = Type("FormField") Or FormItem.Type = Type("FormButton") Then
		SearchStringWithoutSpaces = StrReplace(SearchString, " ", "");
		FoundRow = StrFindAndHighlightByAppearance(FormItem.Name, SearchStringWithoutSpaces);
		If FoundRow = Undefined Then
			If StrFind(Lower(FormItem.Name), Lower(SearchStringWithoutSpaces)) > 0 Then
				FoundRow = FormItem.Name;
			EndIf;
		EndIf;
		AddStringToArrayOfStrings(RowsArray, FoundRow, FormItem.Name);
		RowFound = RowFound Or FoundRow <> Undefined;
	EndIf;
	
	If ValueIsFilled(FormItem.ToolTip) Then
		FoundRow = StrFindAndHighlightByAppearance(FormItem.ToolTip, SearchString);
		AddStringToArrayOfStrings(RowsArray, FoundRow, FormItem.ToolTip);
		RowFound = RowFound Or FoundRow <> Undefined;
	EndIf;
	
	If ValueIsFilled(FormItem.ExtendedTooltip) Then
		FoundRow = StrFindAndHighlightByAppearance(FormItem.ExtendedTooltip, SearchString);
		AddStringToArrayOfStrings(RowsArray, FoundRow, FormItem.ExtendedTooltip);
		RowFound = RowFound Or FoundRow <> Undefined;
	EndIf;
	
	If Not RowFound And SearchIndexElement <> Undefined Then
		FoundRow = StrFindAndHighlightByAppearance(SearchIndexElement, SearchString);
		If FoundRow <> Undefined Then
			RowFound = True;
			
			RowsArray.Add(Chars.LF);
			RowsArray.Add(FoundRow);
			
		EndIf;
	EndIf;
	
	If RowFound And RowsArray.Count() > 0 Then
		
		Result = New FormattedString(RowsArray);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddStringToArrayOfStrings(RowsArray, FoundRow, DefaultString)
	
	If RowsArray.Count() > 0 Then
		RowsArray.Add(Chars.LF);
	EndIf;
	
	If FoundRow <> Undefined Then
		RowsArray.Add(FoundRow);
	Else
		RowsArray.Add(DefaultString);
	EndIf;
	
EndProcedure

Function ElementIsVisible(FormItem)
	
	Visible = False;
	
	//@skip-check empty-except-statement
	Try
		Visible = FormItem.Visible;
	Except
	EndTry;
	
	Visible = Visible And CheckVisibilityOfParents(FormItem);
	
	Return Visible;
	
EndFunction

// Check the visibility of parents.
// 
// Parameters:
//  Item - FormDecoration, FormButton, FormField, FormGroup, ClientApplicationForm, FormTable - Item
// 
// Returns:
//  Boolean - indicates whether the element's parents are visible.
Function CheckVisibilityOfParents(Item)
	If Item.Parent = Undefined 
		Or TypeOf(Item.Parent) = Type("ClientApplicationForm") Then
		
		Return True;
	ElsIf Item.Parent.Visible Then
		Return CheckVisibilityOfParents(Item.Parent);
	Else
		Return False;
	EndIf;
EndFunction

Function SearchForms()
	
	ArrayOfForms = New Array;
	If Not UsersClient.IsExternalUserSession() Then
		ArrayOfForms.Add("CommonForm.PersonalSettings");
	EndIf;
	If UsersClient.IsFullUser()
		And Not StandardSubsystemsClient.IsBaseConfigurationVersion() Then
			
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.BudgetingAndPlanning");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.Purchases");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.CRMAndMarketing");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.ProductSettings");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.CWPAndEquipmentSettings");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.InitialFilling");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.Sales");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.WarehouseAndDelivery");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.FinancialResultAndControlling");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.Enterprise");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.VATAccountingImportExport");
		ArrayOfForms.Add("DataProcessor.TMAdministrationPanel.Form.ProcessDescriptions");
		ArrayOfForms.Add("DataProcessor.CAAdministrationPanel.Form.Production");
		ArrayOfForms.Add("DataProcessor.CAAdministrationPanel.Form.NonCurrentAssets");
		ArrayOfForms.Add("DataProcessor.AdministrationPanelERP.Form.InternationalFinancialAccounting");
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.SupportAndService");
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.CommonSettings");
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.UsersAndRightsSettings");
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.Organizer");
		
		If CommonClient.SeparatedDataUsageAvailable() Then
			DataProcessorName      = "SSLAdministrationPanel";
			DataProcessorFormName = "DataSynchronization";
		Else
			DataProcessorName      = "SSLAdministrationPanelSaaS";
			DataProcessorFormName = "DataSynchronizationForServiceAdministrator";
		EndIf;
		NameOfFormToOpen_ = "DataProcessor.[DataProcessorName].Form.[DataProcessorFormName]";
		NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorName]", DataProcessorName);
		NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorFormName]", DataProcessorFormName);
		ArrayOfForms.Add(NameOfFormToOpen_);
		
		FormName = "DataProcessor.SSLAdministrationPanel.Form.FilesOperationSettings";
		If Not CommonClient.SeparatedDataUsageAvailable() Then
			FormName = FormName + "InSaaS";
		EndIf;
		ArrayOfForms.Add(FormName);
		
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.PrintFormsReportsAndDataProcessors");
		
		ArrayOfForms.Add("DataProcessor.AdministrationPanelDMIL.Form.IntegrationWith1CDocumentManagementSettingOverridable");
		
	EndIf;
	
	If UsersClient.IsFullUser()
		And StandardSubsystemsClient.IsBaseConfigurationVersion() Then
		
		ArrayOfForms.Add("CommonForm.ФормаНастройкиОрганизации");
		ArrayOfForms.Add("CommonForm.ФормаНастройкиРазделаЗакупки");
		ArrayOfForms.Add("CommonForm.ФормаНастройкиРазделаПродажи");
		ArrayOfForms.Add("CommonForm.ФормаНастройкиРазделаСклад");
		ArrayOfForms.Add("DataProcessor.SSLAdministrationPanel.Form.UsersAndRightsSettings");
		
	EndIf;
	
	SystemSettingsClientLocalization.AddSearchForms(ArrayOfForms);
	Return ArrayOfForms
	
EndFunction

Function SearchStringMeetsRequirements(Val SearchString)
	
	If TypeOf(SearchString) <> Type("String")
		Or StrLen(SearchString) < 4
		Or StrStartsWith(SearchString, "e1c") Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

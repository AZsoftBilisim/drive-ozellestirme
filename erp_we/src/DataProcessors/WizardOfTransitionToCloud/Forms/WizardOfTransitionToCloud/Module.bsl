
#Region Variables

&AtClient
Var DataWriter;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ConfigurationName = AppTypesServer.CurrentAppTypeName();
	ConfigurationSynonym = AppTypesServer.CurrentAppTypePresentation();
	ConfigurationVersion = Metadata.Version;
	TimeZone = SessionTimeZone();
	ApplicationDescription = ConfigurationSynonym;
	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
	
	Items.PictureBoxCloud.Visible = Not DataSeparationEnabled;
	Items.PictureBoxFile.Visible = Not DataSeparationEnabled;
	Items.PictureCloudCloud.Visible = DataSeparationEnabled;
	Items.ImageCloudFile.Visible = DataSeparationEnabled;
	
	Items.GetTheUploadFileInTheServiceModel.Visible = DataSeparationEnabled;
	Items.GetTheUploadFile.Visible = Not DataSeparationEnabled;
	Items.NoteAnUpdateIsRequiredInTheServiceModel.Visible = DataSeparationEnabled;
	Items.NoteTheUpgradeIsRequired.Visible = Not DataSeparationEnabled;
	
	If Common.SubsystemExists("CloudTechnology.ApplicationsSize") Then
		ModuleSizeOfApplications = Common.CommonModule("ApplicationsSize");
		SupportedSizeCalculation = ModuleSizeOfApplications.ApplicationSizeCalculationIsSupported();
	Else
		SupportedSizeCalculation = False;
	EndIf;
	Items.ApplicationSizeGroup.Visible = SupportedSizeCalculation;
	
		Items.NoteTheUpgradeIsRequired.Title = String(Items.NoteTheUpgradeIsRequired.Title);
	
	If DataSeparationEnabled Then
		Items.ComparisonParametersHeader.Title = StrTemplate(NStr("vi = 'Chọn tùy chọn %1 chuyển:';
																	|ru = 'Выберите вариант%1переноса:';
																	|en = 'Select transfer%1option:'; fa = 'Select transfer%1option:';
																	|it = 'Seleziona l''opzione%1di trasferimento:';
																	|pl = 'Wybierz wariant%1przeniesienia:';
																	|tr = 'Taşıma%1seçeneğini seçin:'"), Chars.LF);
		Items.Parameter1.Title = NStr("vi = 'Có thể tiếp tục làm việc trong ứng dụng hiện tại trong quá trình chuyển';
										|ru = 'Можно продолжать работу в текущем приложении в процессе переноса';
										|en = 'You can continue working in the current application during transfer'; fa = 'You can continue working in the current application during transfer';
										|it = 'È possibile continuare il lavoro nell''applicazione corrente durante il trasferimento';
										|pl = 'Można kontynuować pracę w bieżącej aplikacji w trakcie przeniesienia';
										|tr = 'Taşıma işlemi süreci boyunca mevcut uygulamada çalışmaya devam edebilirsiniz'");
		Items.Parameter2.Title = NStr("vi = 'Dữ liệu sẽ tự động cập nhật lên phiên bản chính xác trong quá trình chuyển';
										|ru = 'Данные автоматически обновятся до нужной версии в процессе переноса';
										|en = 'Data will be automatically updated to the required version on transfer'; fa = 'Data will be automatically updated to the required version on transfer';
										|it = 'I dati verranno aggiornati automaticamente alla versione richiesta durante il trasferimento';
										|pl = 'Dane zostaną automatycznie zaktualizowane do wymaganej wersji w trakcie przeniesienia';
										|tr = 'Taşıma işlemi sırasında veriler otomatik olarak doğru sürüme güncellenecektir'");
		Items.FileTransitionMethod.ChoiceList[0].Presentation =	NStr("vi = 'Lấy tệp tải lên để chuyển thủ công.';
																		|ru = 'Получите файл выгрузки для ручного переноса.';
																		|en = 'Get an export file for manual transfer.'; fa = 'Get an export file for manual transfer.';
																		|it = 'Ottieni il file di upload per il trasferimento manuale.';
																		|pl = 'Pobierz plik eksportu dla ręcznego przeniesienia.';
																		|tr = 'Manuel geçiş için dışa aktarma dosyasını alın.'"); 
		Items.TransitionMethodCloud.ChoiceList[0].Presentation = StrTemplate(
			NStr("vi = 'Nhập địa chỉ dịch vụ %1 để chuyển tự động:';
				|ru = 'Введите адрес сервиса%1для автоматического переноса:';
				|en = 'Enter the service address%1for automatic transfer:'; fa = 'Enter the service address%1for automatic transfer:';
				|it = 'Inserisci l''indirizzo del servizio%1per il trasferimento automatico:';
				|pl = 'Wpisz adres serwisu%1 dla automatycznego przeniesienia:';
				|tr = 'Otomatik taşıma için%1servis adresini giriniz:'"), Chars.LF);
		
		RecommendationText = NStr("vi = 'Thông tin chi tiết dành cho bộ phận hỗ trợ được ghi lại trong nhật ký sự kiện.
			|Nếu không thể sửa lỗi, hãy liên hệ với bộ phận hỗ trợ kỹ thuật.';
			|ru = 'Расширенная информация для службы поддержки записана в журнал регистрации.
			|Если устранить ошибку не удается, рекомендуется обратиться в службу технической поддержки.';
			|en = 'Detailed information for the technical support is saved to the event log.
			|If you cannot resolve the error, please contact the technical support.'; fa = 'Detailed information for the technical support is saved to the event log.
			|If you cannot resolve the error, please contact the technical support.';
			|it = 'Informazione dettagliate per il servizio di supporto registrate nel registro.
			|Se risulta impossibile risolvere l''errore, si consiglia di rivolgersi al servizio di supporto tecnico.';
			|pl = 'Rozszerzone informacje dla pomocy technicznej są zapisane do dziennika rejestracji.
			|Jeśli nie da się usunąć błędu, zaleca się zwrócić się do pomocy technicznej.';
			|tr = 'Gelişmiş destek bilgileri günlüğe kaydedilir.
			|Hata çözülmezse, teknik destek servisiyle iletişime geçmeniz önerilmektedir.'");
	Else
		RecommendationText = NStr("vi = 'Thông tin chi tiết dành cho bộ phận hỗ trợ được ghi lại vào nhật ký sự kiện.
			|Nếu không thể sửa lỗi, hãy liên hệ với bộ phận hỗ trợ kỹ thuật, đồng thời cung cấp thông tin và kết xuất nhật ký sự kiện để điều tra lỗi.';
			|ru = 'Расширенная информация для службы поддержки записана в журнал регистрации.
			|Если устранить ошибку не удается, рекомендуется обратиться в службу технической поддержки, предоставив для расследования информационную базу и выгрузку журнала регистрации.';
			|en = 'Detailed information for the technical support is saved to the event log.
			|If you cannot resolve the error, please contact the technical support and provide the infobase and the event log.'; fa = 'Detailed information for the technical support is saved to the event log.
			|If you cannot resolve the error, please contact the technical support and provide the infobase and the event log.';
			|it = 'Informazioni dettagliate per il servizio di supporto sono registrate nel registro.
			|Se risulta impossibile risolvere l''errore, si consiglia di rivolgersi al servizio di supporto tecnico, fornendo l''''infobase e upload del registro degli eventi per l''analisi.';
			|pl = 'Rozszerzona informacja dla służby pomocy została zapisana do dziennika rejestracji.
			|Jeśli nie udaje się usunąć błędu, zaleca się skontaktować się z pomocą techniczną, udzielając do zbadania bazę informacyjną i wyciąg z dziennika rejestracji.';
			|tr = 'Gelişmiş destek bilgileri günlüğe kaydedilir.
			|Hata çözülemezse, inceleme için infobase sağlayarak ve günlüğü indirerek teknik destek servisiyle iletişime geçmeniz önerilmektedir.'");
	EndIf; 
	
	Items.RecommendationError.Title = RecommendationText;
	
	GreetingTitle = ?(DataSeparationEnabled, 
		NStr("vi = 'Chuyển dữ liệu ứng dụng';
			|ru = 'Перенос данных приложения';
			|en = 'Application data transfer'; fa = 'انتقال داده‌های برنامه';
			|it = 'Trasferimento dati applicazione';
			|pl = 'Przeniesienie danych aplikacji';
			|tr = 'Uygulama verilerini taşı'"),
		NStr("vi = 'Chuyển sang dịch vụ đám mây';
			|ru = 'Переход в облачный сервис';
			|en = 'Cloud migration'; fa = 'مهاجرت ابری';
			|it = 'Passaggio nel servizio cloud';
			|pl = 'Przejście do serwisu w chmurze';
			|tr = 'Bulut hizmetine geçiş'"));
		
	Title = GreetingTitle;
	
	Items.Back.Visible = False;
	Items.PasswordIsOpen.Visible = False;
	Items.PasswordIsOpen.ChoiceButtonPicture = Items.PictureOpen.Picture;
	Items.PasswordIsPrivate.ChoiceButtonPicture = Items.ThePictureIsClosed.Picture;
	
	CheckInOption = OptionAutomaticOoAssignment();
	
	CurrentUser = Users.CurrentUser();
	If ValueIsFilled(CurrentUser) Then
		CurrentUserID = CurrentUser.UUID();
	EndIf; 
	
	Items.PickUpTheOOAutomatically.ChoiceList.Add(
		OptionAutomaticOoAssignment(), NStr("vi = 'Tự động chọn một doanh nghiệp dịch vụ';
											|ru = 'Подобрать обслуживающую организацию автоматически';
											|en = 'Pick service provider automatically'; fa = 'Pick service provider automatically';
											|it = 'Selezionare l''azienda di servizio automaticamente';
											|pl = 'Wybierz firmę obsługującą automatycznie';
											|tr = 'Hizmet veren iş yerini otomatik seç'"));
	Items.SelectOO.ChoiceList.Add(
		OptionOoSelection(), NStr("vi = 'Chọn doanh nghiệp';
									|ru = 'Выбрать организацию';
									|en = 'Select service provider'; fa = 'انتخاب ارائه‌دهنده خدمات';
									|it = 'Selezionare azienda';
									|pl = 'Wybierz firmę';
									|tr = 'İş yeri seç'"));
	Items.EnterTheActivationCode.ChoiceList.Add(
		OptionEnterActivationCode(), NStr("vi = 'Nhập mã kích hoạt đã nhận từ trước';
											|ru = 'Ввести код активации, полученный ранее';
											|en = 'Enter your activation code'; fa = 'Enter your activation code';
											|it = 'Ввести код активации, полученный ранее';
											|pl = 'Enter your activation code';
											|tr = 'Daha önce alınan etkinleştirme kodunu gir'"));
	
	FillIBUsers();
			
	FillInIBExtensions();
	
	ParallelLoadingOptions = ExportImportDataInternal.ParallelDataExportImportParameters();
	
	If ParallelLoadingOptions.AvailableUsage Then
		ExportDataJobsCount = ParallelLoadingOptions.ThreadsCount;
	Else
		ExportDataJobsCount = 1;
		Items.GroupParallelExport.Visible = False;
	EndIf;
	
	CheckingForPlusExtensions();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Items.Pages.CurrentPage = Items.PageGreeting Then
		If Not TransitionMethod = MethodFile() And Not ValueIsFilled(ServiceAddress) Then
			If DataSeparationEnabled Then
				Common.MessageToUser(
					NStr("vi = 'Kiểm tra tính khả dụng của chuyển dịch vụ không được thực hiện. Nhập địa chỉ dịch vụ chính xác.';
						|ru = 'Не выполнена проверка доступности переноса в сервис. Укажите корректный адрес сервиса.';
						|en = 'Cannot check whether transfer to the service is available. Enter the correct service address.'; fa = 'Cannot check whether transfer to the service is available. Enter the correct service address.';
						|it = 'Verifica della disponibilità di trasferimento nel servizio non è stata eseguita. Indicare l''indirizzo corretto del servizio.';
						|pl = 'Nie wykonano weryfikacji dostępności przeniesienia do serwisu. Podaj poprawny adres serwisu.';
						|tr = 'Servise aktarımın kullanılabilirliği için kontrol yapılmadı. Lütfen geçerli servis adresi girin.'"),,
					"ServiceAddress",, Cancel);
			Else
				Common.MessageToUser(
					NStr("vi = 'Kiểm tra tính khả dụng của chuyển dịch vụ không được thực hiện. Nhập địa chỉ dịch vụ chính xác.';
						|ru = 'Не выполнена проверка доступности перехода в сервис. Укажите корректный адрес сервиса.';
						|en = 'Cannot check whether migration to the service is available. Enter the correct service address.'; fa = 'Cannot check whether migration to the service is available. Enter the correct service address.';
						|it = 'Verifica della disponibilità di passaggio al servizio non è stata eseguita. Indicare l''indirizzo corretto del servizio.';
						|pl = 'Nie wykonano weryfikacji dostępności przejścia do serwisu. Podaj poprawny adres serwisu.';
						|tr = 'Servise geçişin kullanılabilirliği için kontrol yapılmadı. Lütfen geçerli servis adresi girin.'"),,
					"ServiceAddress",, Cancel);
			EndIf; 
		EndIf; 
		
	ElsIf Items.Pages.CurrentPage = Items.LoginPage Then
		CheckedAttributes.Add("Login");
		CheckedAttributes.Add("Password");
		
	ElsIf Items.Pages.CurrentPage = Items.EnterInformationPage Then
		If CheckInOption = OptionEnterActivationCode() Then
			CheckedAttributes.Add("ActivationCode");
		EndIf;
		CheckedAttributes.Add("RegistrationName");
		If CheckInOption <> OptionEnterActivationCode() Then 
			CheckedAttributes.Add("RegistrationMail");
		EndIf; 
		CheckedAttributes.Add("RegistrationPassword");
		CheckedAttributes.Add("RegistrationPasswordConfirmation");
		
		If RegistrationPassword <> RegistrationPasswordConfirmation Then
			Common.MessageToUser(
				NStr("vi = 'Mật khẩu và xác nhận mật khẩu không khớp.';
					|ru = 'Пароль и подтверждение пароля не совпадают.';
					|en = 'Password and confirmation password do not match.'; fa = 'Password and confirmation password do not match.';
					|it = 'Password e conferma password non coincidono.';
					|pl = 'Hasło i potwierdzenie hasła nie różnią się.';
					|tr = 'Şifre ve şifre onayı uyumlu değil.'"),, 
				"RegistrationPasswordConfirmation",, Cancel); 
			Return;	
		EndIf; 
		If Not Confirmation Then
			Common.MessageToUser(
				NStr("vi = 'Cần xác nhận';
					|ru = 'Требуется подтверждение';
					|en = 'Confirmation is required'; fa = 'تأیید الزامی است';
					|it = 'Conferma richiesta';
					|pl = 'Wymagane jest potwierdzenie';
					|tr = 'Onaylama gerekli'"),, 
				"Confirmation",, Cancel); 
			Return;
		EndIf; 	
		
	ElsIf Items.Pages.CurrentPage = Items.EnterActivationCodePage Then
		CheckedAttributes.Add("ActivationCode");
		
	ElsIf Items.Pages.CurrentPage = Items.SelectRegistrationOptionPage Then
		If CheckInOption = OptionOoSelection() Then
			CheckedAttributes.Add("SPCode");
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.PageSelectingTheTransitionMethod Then
		CheckedAttributes.Add("SubscriberCode_2");
		
	ElsIf Items.Pages.CurrentPage = Items.UsersMappingPage Then
		LineNumber = -1;
		For Each String In UsersRights Do
		    LineNumber = LineNumber + 1;
			If ValueIsFilled(String.Right) And Not ValueIsFilled(String.Id) Then
				Common.MessageToUser(
					StrTemplate(NStr("vi = 'Đối với người sử dụng dịch vụ ''%1'' có quyền ''%2'' chưa chỉ ra người sử dụng từ cơ sở dữ liệu.';
									|ru = 'Для пользователя сервиса ''%1'' с правом ''%2'' не указан пользователь из базы.';
									|en = 'Infobase user is not specified for the ''%1'' service user with the ''%2'' access right.'; fa = 'Infobase user is not specified for the ''%1'' service user with the ''%2'' access right.';
									|it = 'Per l''utente del servizio ''%1'' con il diritto ''%2'' non è stato indicato l''utente del database.';
									|pl = 'Dla użytkownika serwisu ''%1'' z prawem ''%2'' nie jest podany użytkownik z bazy.';
									|tr = '''%2'' iznine sahip ''%1'' servis kullanıcısının belirtilen tabanı kullanıcısı yok.'"), 
						String.FullName, PresentationOfUserRights(String.Right)),, 
					StrTemplate("UsersRights[%1].FullNameOfTheIBUser", Format(LineNumber,"NG=0")),, Cancel); 
			EndIf; 
			If ValueIsFilled(String.Id) And ValueIsFilled(String.Login) And Not ValueIsFilled(String.Right) Then
				Common.MessageToUser(
					StrTemplate(NStr("vi = 'Đối với người sử dụng dịch vụ ''%1'' chưa chỉ ra quyền của người sử dụng từ cơ sở dữ liệu.';
									|ru = 'Для пользователя сервиса ''%1'' не указано право пользователя из базы.';
									|en = 'Infobase user access right is not specified for the ''%1'' service user.'; fa = 'Infobase user access right is not specified for the ''%1'' service user.';
									|it = 'Per l''utente del servizio ''%1'' non è stato indicato il diritto dell''utente dal database.';
									|pl = 'Dla użytkownika serwisu ''%1'' nie podano prawa użytkownika z bazy.';
									|tr = '''%1'' servis kullanıcısı için tabandan kullanıcı erişim yetkisi belirtilmemiş.'"), String.FullName),, 
					StrTemplate("UsersRights[%1].Right", Format(LineNumber,"NG=0")),, Cancel); 
			EndIf; 
		EndDo; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	Form = ApplicationParameters.Get("CloudTechnology.ApplicationsMigration.GoToServiceForm");
	If Form <> Undefined Then
		Close();
		If Not Form.IsOpen() Then
			Form.Open();
		Else
			Form.Activate();
		EndIf;
	Else
		CheckServiceAddress();
    EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If ValueIsFilled(JobID) Then
		CancelPreparationTask(JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or CloseOfCourse = True Then
		Return;
	EndIf;
	
	Cancel = True;
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("BeforeClosingAlert", ThisObject);
	QueryText = NStr("vi = 'Đóng trợ giúp?';
					|ru = 'Закрыть помощник?';
					|en = 'Do you want to close the assistant?'; fa = 'Do you want to close the assistant?';
					|it = 'Chiudere assistente?';
					|pl = 'Zamknij asystenta?';
					|tr = 'Sihirbaz kapatılsın mı?'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TransitionMethodCloudOnChange(Item)
	
	WhenChangingTransitionMethodOnMainPage();
	
EndProcedure

&AtClient
Procedure FileTransitionMethodOnChange(Item)
	
	WhenChangingTransitionMethodOnMainPage();
	
EndProcedure

&AtClient
Procedure ServiceAddressOnChange(Item)
	
	CheckServiceAddress();
	
EndProcedure

&AtClient
Procedure RecoveryRegistrationLinkProcessing(Item, RowNavigationLink, StandardProcessing)
	
	If RowNavigationLink = RefRegistration() Then
		StandardProcessing = False;
		If AnInvitationToRegisterIsAvailable Then
			SetSelectRegistrationOptionPage(Items.Pages.CurrentPage);
		Else
			CheckInOption = OptionRequestForRegistration();
			SetEnterDetailsPage(Items.Pages.CurrentPage);
		EndIf; 
	EndIf; 
	
EndProcedure

&AtClient
Procedure ServiceOrganizationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("CloudServiceAddress", ServiceAddress);
	Notification = New CallbackDescription("ChoosingOrganizationCompletion", ThisObject);
	CheckInOption = OptionOoSelection();
	ChoiceFormName = "DataProcessor.WizardOfTransitionToCloud.Form.ServiceProviderSelection";
	OpenForm(ChoiceFormName, FormParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure ServiceOrganizationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PasswordIsPrivateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Items.PasswordIsPrivate.Visible = False;
	Items.PasswordIsOpen.Visible = True;
	
EndProcedure

&AtClient
Procedure PasswordIsOpenStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Items.PasswordIsPrivate.Visible = True;
	Items.PasswordIsOpen.Visible = False;
	
EndProcedure

&AtClient
Procedure AssignAPartnerWhenAChangeOccurs(Item)
	
	WhenChangingRegistrationOption();
	
EndProcedure

&AtClient
Procedure EnterTheActivationCodeOnChange(Item)
	
	WhenChangingRegistrationOption();
	
EndProcedure

&AtClient
Procedure ActivationCodeEditTextChange(Item, Text, StandardProcessing)
	
	Items.ActivationCode.TextColor = WebColors.Black;
	
EndProcedure

&AtClient
Procedure ActivationCodeOnChange(Item)
	
	CheckActivationCode();
	
EndProcedure

&AtClient
Procedure ActivationCodeRegistrationRequestOnChange(Item)
	
	StartActivatingRegistrationCode();
	
EndProcedure

&AtClient
Procedure RegistrationNameOnChange(Item)
	
	ShowFillInFlag(RegistrationName, Items.CheckingTheName.Name);
	
EndProcedure

&AtClient
Procedure RegistrationMailOnChange(Item)
	
	CheckEmailAddress();
	
EndProcedure

&AtClient
Procedure RegistrationPhoneOnChange(Item)
	
	ShowFillInFlag(RegistrationPhone, Items.CheckingYourPhone.Name);
	
EndProcedure

&AtClient
Procedure RegistrationPasswordOnChange(Item)
	
	CheckPasswordEntry();
	
EndProcedure

&AtClient
Procedure RegistrationPasswordConfirmationOnChange(Item)
	
	CheckPasswordEntry();
	
EndProcedure

&AtClient
Procedure TransitionMethodUploadOnChange(Item)
	
	WhenChangingTransitionMethod();
	
EndProcedure

&AtClient
Procedure TransitionMethodMigrationOnChange(Item)
	
	WhenChangingTransitionMethod();
	
EndProcedure

&AtClient
Procedure UploadHeaderClick(Item)
	
	TransitionMethod = UploadMethod();
	WhenChangingTransitionMethod();
	
EndProcedure

&AtClient
Procedure MigrationCapClick(Item)
	
	TransitionMethod = MethodMigration();
	WhenChangingTransitionMethod();
	
EndProcedure

&AtClient
Procedure GetFileUploadLinkProcessing(Item, RowNavigationLink, StandardProcessing)
	
	StandardProcessing = False;
	SetDataUploadPage(Items.Pages.CurrentPage, True);
	
EndProcedure

&AtClient
Procedure NoteUpdateLinkProcessingRequired(Item, RowNavigationLink, StandardProcessing)
	
	StandardProcessing = False;
	CloseOfCourse = True;
	Close();
	GotoURL("e1cib/app/DataProcessor.ApplicationUpdate");
	
EndProcedure

&AtClient
Procedure DescriptionInformationLinkProcessing(Item, RowNavigationLink, StandardProcessing)
	
	StandardProcessing = False;
	GotoURL(StrTemplate("%1?N=%2&P=%3&OIDA-", PersonalAccountAddress, Login, Password));
	
EndProcedure

&AtClient
Procedure CheckMailAnEnhancedTooltipHandlingLinks(Item, RowNavigationLink, StandardProcessing)
	
	StandardProcessing = False;
	If CheckInOption = OptionRequestForRegistration() Then
		SetPageEnterActivationCode(Items.Pages.CurrentPage);	
	EndIf; 
	
EndProcedure

&AtClient
Procedure StatusTextLinkProcessing(Item, RowNavigationLink, StandardProcessing)
	
	StandardProcessing = False;
	If RowNavigationLink = RetryAppCreationLink() Then
		CreateApplicationFromFile();
		
	ElsIf RowNavigationLink = RetryDataTransferLink() Then
		StartDataTransfer(Items.Pages.CurrentPage);	
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure DecorationAverageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	OpenHelp("CommonForm.DataImportFromService");
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersRecoveryExtensions

&AtClient
Procedure RecoveryExtensionsUseExtensionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("ExtensionsStorageURL", ExtensionsStorageURL);
	FormParameters.Insert("ModifiesDataStructure",
		Items.RecoveryExtensions.CurrentData.ModifiesDataStructure);
	Notification = New CallbackDescription("ProcessExtensionSelection", ThisObject);
	OpenForm(
		"DataProcessor.WizardOfTransitionToCloud.Form.ExtensionsSelection", 
		FormParameters, ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure RecoveryExtensionsUseExtensionClearing(Item, StandardProcessing)
	Items.RecoveryExtensions.CurrentData.Version = "";
EndProcedure

&AtClient
Procedure RecoveryExtensionsUseExtensionStartListChoice(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersRights

&AtClient
Procedure UsersRightsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "UsersRightsHyperlink" Then
		StandardProcessing = False;
		CreateServiceUser();
	EndIf; 
	
EndProcedure

&AtClient
Procedure UsersRightsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	CreateServiceUser();
	
EndProcedure

&AtClient
Procedure UserRightsUserStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	UsersList = New ValueList;
	For Each TableRow In IBUsers Do
		ListItem = UsersList.Add(TableRow, TableRow.FullName);
		If TableRow.Id = Items.UsersRights.CurrentData.Id Then
			InitialValue = ListItem;
		EndIf;
	EndDo;
	
	Notification = New CallbackDescription("ChoosingInformationSecurityUser", ThisObject);
	ShowChooseFromList(Notification, UsersList, Item, InitialValue);
	
EndProcedure

&AtClient
Procedure UsersRightsFullNameOfTheIBUserClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.UsersRights.CurrentData;
	If ValueIsFilled(CurrentData.Id) Then
		Search = IBUsers.FindRows(New Structure("Id", CurrentData.Id));
		If Search.Count() > 0 Then
			Search[0].ServiceUserLogin = "";
		EndIf;
		CurrentData.Id = Undefined;
		CurrentData.User = Undefined;
		CurrentData.Right = Undefined;
		CurrentData.FullNameOfTheIBUser = Undefined;
	EndIf; 
	
	AddUnmappedUsersToList();
	UpdateUserMappingStatus();
	
EndProcedure
 
#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	GoNext(Items.Pages.CurrentPage);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	GoBack_(Items.Pages.CurrentPage);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure ShowHidePassword(Command)
	
	Items.RegistrationPassword.PasswordMode = Not Items.RegistrationPassword.PasswordMode;
	Items.RegistrationPasswordConfirmation.PasswordMode = Not Items.RegistrationPasswordConfirmation.PasswordMode;
	If Items.RegistrationPassword.PasswordMode Then
		Items.ShowHidePassword.Picture = Items.ThePictureIsClosed.Picture;
	Else
		Items.ShowHidePassword.Picture = Items.PictureOpen.Picture;
	EndIf; 
	
EndProcedure

#EndRegion 

#Region Private

&AtClient
Function ServiceManagerSupportsMigrationWithExtensions()
	Return SoftwareInterfaceVersion >= 24;
EndFunction

&AtClient
Function CheckIfYouCanAutomaticallyNavigateWithExtensions()	
	
	If TransitionMethod = MethodMigration() And ServiceManagerSupportsMigrationWithExtensions() Then
		Return True;
	EndIf;
	
	Try
		// Backward compatibility support.
		WarningText = Eval(
			"CommonServerCallCTL.WarningTextAboutActiveExtensionsThatChangeDataStructure()");
	Except
		WarningText = "";
	EndTry;
	
	If Not ValueIsFilled(WarningText) Then
		Return True;
	EndIf;
	
	QuestionRows = New Array;
	QuestionRows.Add(NStr("vi = 'Hiện tại không hỗ trợ chuyển đổi tự động sang dịch vụ có phần mở rộng thay đổi cấu trúc dữ liệu.';
							|ru = 'Автоматический переход в сервис с расширениями, изменяющими структуру данных, в данный момент не поддерживается.';
							|en = 'Automatic migration to the service with extensions that change the data structure is currently not supported.'; fa = 'Automatic migration to the service with extensions that change the data structure is currently not supported.';
							|it = 'Il trasferimento automatico al servizio con estensioni che modificano la struttura dei dati non è attualmente supportata.';
							|pl = 'Automatyczne przejście do serwisu z rozszerzeniami, zmieniającymi strukturę danych, w tej chwili nie jest obsługiwane.';
							|tr = 'Veri yapısını değiştiren uzantılara sahip servise otomatik geçiş şu anda desteklenmemektedir.'"));
	QuestionRows.Add(Chars.LF);
	QuestionRows.Add(NStr("vi = 'Để tiếp tục, cần xóa tất cả phần mở rộng thay đổi cấu trúc dữ liệu hoặc sử dụng phương án chuyển thủ công hoặc kết xuất dữ liệu từng phần.';
							|ru = 'Для продолжения необходимо удалить все расширения, изменяющие структуру данных, или использовать вариант ручного перехода, или порционную выгрузку данных.';
							|en = 'To continue, delete all extensions that change the data structure or use manual migration or batch data export.'; fa = 'To continue, delete all extensions that change the data structure or use manual migration or batch data export.';
							|it = 'To continue, delete all extensions that change the data structure or use manual migration or batch data export.';
							|pl = 'To continue, delete all extensions that change the data structure or use manual migration or batch data export.';
							|tr = 'Devam edebilmek için veri yapısını değiştirebilecek tüm eklentileri kaldırmanız veya manuel geçiş seçeneğini ya da toplu veri boşaltma özelliğini kullanmanız gerekmektedir.'"));
	QuestionRows.Add(NStr("vi = 'Chúng tôi khuyên bạn trước hết nên tạo bản sao dự phòng.';
							|ru = 'Рекомендуем предварительно создать резервную копию.';
							|en = 'We recommend that you create a backup first.'; fa = 'We recommend that you create a backup first.';
							|it = 'Si consiglia di creare un backup prima di procedere.';
							|pl = 'Zalecamy wstępnie utworzyć kopię zapasową.';
							|tr = 'Önceden yedek oluşturmanızı öneririz.'"));
	QuestionRows.Add(Chars.LF);
	QuestionRows.Add(WarningText);
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Picture = PictureLib.Warning32;
	QuestionParameters.Title = NStr("vi = 'Phần mở rộng cấu hình thay đổi cấu trúc dữ liệu đang hoạt động';
									|ru = 'Активны расширения конфигурации, изменяющие структуру данных';
									|en = 'Configuration extensions that change the data structure are active'; fa = 'Configuration extensions that change the data structure are active';
									|it = 'Le estensioni di configurazione che modificano la struttura dei dati sono abilitate';
									|pl = 'Aktywne rozszerzenia konfiguracji, zmieniające strukturę danych';
									|tr = 'Veri yapısını değiştiren konfigürasyon uzantıları etkin durumda'");

	StandardSubsystemsClient.ShowQuestionToUser(
		Undefined,
		StrConcat(QuestionRows, Chars.LF),
		QuestionDialogMode.OK,
		QuestionParameters);
		
	Return False;	
		
EndFunction

#Region DataExport

&AtClient
Procedure StartUploadingData()
	
	If ExportModeForTechnicalSupport Then
		CallbackDescription = New CallbackDescription(
			"UploadingDataForTechnicalSupportCheckingCompletion", ThisObject);
		
		PartsOfQuestionLine = New Array;
		PartsOfQuestionLine.Add(
			NStr("vi = 'Trong chế độ kết xuất để hỗ trợ kỹ thuật, các tệp đính kèm, phiên bản đối tượng, v. v. sẽ không được kết xuất.';
				|ru = 'В режиме выгрузки для технической поддержки не будут выгружаться присоединенные файлы, версии объектов и др.';
				|en = 'In export mode, attached files, object versions, and so on will not be exported for technical support.'; fa = 'In export mode, attached files, object versions, and so on will not be exported for technical support.';
				|it = 'I file allegati, le versioni degli oggetti ecc. non verranno caricati in modalità upload per l''assistenza tecnica.';
				|pl = 'W trybie eksportowania w celu wsparcia technicznego nie będą eksportowane załączone pliki, wersje obiektów i inne.';
				|tr = 'Destek hizmeti için dışa aktarma modunda, ekli dosyalar, nesnelerin sürümleri vb. yüklenmeyecektir.'"));
		PartsOfQuestionLine.Add(Chars.LF);
		PartsOfQuestionLine.Add(New FormattedString(
			NStr("vi = 'Dữ liệu kết xuất nhận được chỉ dùng để theo dõi vấn đề và thử nghiệm.';
				|ru = 'Полученную выгрузку следует использовать только в целях расследования проблем и тестирования.';
				|en = 'Use the obtained export file only for identifying issues and testing.'; fa = 'Use the obtained export file only for identifying issues and testing.';
				|it = 'L''upload ottenuto deve essere utilizzato solo allo scopo di analisi di problemi e verifiche.';
				|pl = 'Eksportowany plik należy używać tylko w celu rozpatrywania problemów i testowania.';
				|tr = 'Alınan dışa aktarma, yalnızca sorun araştırması ve test etme amacıyla kullanılmalıdır.'"), 
			New Font(,, True), WebColors.Red));
		PartsOfQuestionLine.Add(Chars.LF);
		PartsOfQuestionLine.Add(NStr("vi = 'Tiếp tục?';
									|ru = 'Продолжить?';
									|en = 'Continue?'; fa = 'Continue?';
									|it = 'Continuare?';
									|pl = 'Continue?';
									|tr = 'Devam edilsin mi?'"));
		ShowQueryBox(CallbackDescription, New FormattedString(PartsOfQuestionLine), 
			QuestionDialogMode.OKCancel, , DialogReturnCode.Cancel);
		
	Else
		AfterCheckingUnloadingModeForTechnicalSupport();	
	EndIf;

EndProcedure

&AtClient 
Procedure AfterCheckingUnloadingModeForTechnicalSupport()
	
	Try
		// Backward compatibility support.		
		WarningText = Eval(
			"CommonServerCallCTL.WarningTextAboutActiveExtensionsThatChangeDataStructure()");
	Except
		WarningText = "";
	EndTry;
	
	If Not ValueIsFilled(WarningText) Then
		StartCheckingExportingData();
		Return;
	EndIf;
	
	Items.DecorationUpper.Title = WarningText;

	SetExtensionWarningPage(Items.Pages.CurrentPage);
		
EndProcedure

&AtClient
Procedure UploadingDataForTechnicalSupportCheckingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		AfterCheckingUnloadingModeForTechnicalSupport();	
	EndIf; 
	
EndProcedure

&AtClient 
Procedure StartDataUpload()
	
	Notification = New CallbackDescription("StartUploadingDataAfterInstallingExtension", ThisObject);
	
	If TheFileIsBeingSaved And IsWebClient() Then
		SuggestionText = NStr("vi = 'Tệp kết xuất có thể khá lớn. Trong trường hợp này, cần có phần mở rộng để làm việc với 1C:Enterprise.
                                 |Với phần mở rộng này, làm việc trong web-client sẽ trở nên thuận tiện hơn không chỉ khi làm việc với các tệp lớn.';
                                 |ru = 'Файл выгрузки может оказаться большим. В этом случае потребуется расширение для работы с 1С:Предприятием.
                                 |С этим расширением работа в веб-клиенте станет удобней не только при работе с большими файлами.';
                                 |en = 'The export file might be large. In this case, you need to install 1C:Enterprise Extension.
                                 |This extension improves user experience in web client not only upon using large files.'; fa = 'The export file might be large. In this case, you need to install 1C:Enterprise Extension.
                                 |This extension improves user experience in web client not only upon using large files.';
                                 |it = 'Il file dell''upload potrebbe risultare grande. In questo caso sarà necessaria l''estensione di lavoro con 1C:Enterprise. 
                                 | Questa estensione faciliterà il lavoro nel client web e non esclusivamente per il lavoro con i file di grandi dimensioni.';
                                 |pl = 'Plik wyciągu może okazać się duży. W tym przypadku będzie potrzebne rozszerzenie do pracy z 1С:Enterprise.
                                 |Z tym rozszerzeniem praca w kliencie web będzie wygodniej nie tylko podczas pracy z dużymi plikami.';
                                 |tr = 'Dışa aktarılan dosya büyük olabilir. Bu durumda, 1C:Enterprise ile çalışmak için uzantıya ihtiyacınız olacak.
                                 |Bu uzantıyla, web istemcisinde çalışmak yalnızca büyük dosyalarla çalışırken daha kolay hale gelmeyecek.'");
		FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText);
	Else
		RunCallback(Notification, True);
	EndIf;
	
EndProcedure

&AtClient 
Async Procedure StartUploadingDataAfterInstallingExtension(Attached, AdditionalParameters) Export
	
	FileSystemExtensionAttached1 = Attached;
	
	If TheFileIsBeingSaved And Not FileSystemExtensionAttached1 And AppSizeLargerThanAllowed() Then
		SetPageFileExtensionIsNotEnabled(Items.Pages.CurrentPage);
		Return;
	EndIf;
	
	If TheFileIsBeingSaved And FileSystemExtensionAttached1 Then
		
		FileNameAtClient = GetDataExportFileName(ExportModeForTechnicalSupport);
		
		Dialog = New FileDialog(FileDialogMode.Save);
		Dialog.Title = NStr("vi = 'Nhận tệp kết xuất';
							|ru = 'Получение файла выгрузки';
							|en = 'Save export file'; fa = 'Save export file';
							|it = 'Ricezione del file di upload';
							|pl = 'Pobieranie pliku wyładowania';
							|tr = 'Dışa aktarma dosyasının alımı'");
		Dialog.FullFileName = FileNameAtClient;
		Dialog.Filter = StrTemplate(NStr("vi = 'Tệp nén %1';
										|ru = 'Архивы %1';
										|en = 'Archives %1'; fa = 'Archives %1';
										|it = 'Archivi %1';
										|pl = 'Archiwa %1';
										|tr = 'Arşivler %1'"), "(*.zip)|*.zip");
		Result = Await Dialog.ChooseAsync();
		If Result = Undefined Or Result.Count() = 0 Then
			Close();
			Return;
		EndIf;
		FileNameAtClient = Result[0]; 
		WriteStream = Await FileStreams.OpenAsync(FileNameAtClient, FileOpenMode.Create, FileAccess.Write);
		DataWriter = New DataWriter(WriteStream);
			
	EndIf;
	
	StartExportDataAfterDialog();

EndProcedure

&AtClient
Procedure StartExportDataAfterDialog()
	
	StartDataUploadOnServer();
	
	Title = HeaderUploadingData();
	SetDefaultControls();
	Items.Back.Enabled = False;
	ShowWaitingState("StatePicture");
	
	Items.StatusText_3.Visible = False;
	Items.StatusPresentation.Visible = True;

	Items.Pages.CurrentPage = Items.PageWait;
	Items.Next.Visible = False;
	Items.StatusPresentation.Visible = True; 

	If TheFileIsBeingSaved Then
		Items.WaitingPageNextDescriptionTitle.Visible = False;
	EndIf; 
	
	AttachIdleHandler("CheckReadinessOfUnloading", 5, True);
	
EndProcedure

&AtServer
Procedure StartDataUploadOnServer()
	
	Try
		
		StorageAddress = PutToTempStorage(Undefined, UUID);
		NameOfDataUploadMethod = "ExportImportDataAreas.UploadCurAreaToArchive";
		
		JobParameters = New Array;
		JobParameters.Add(StorageAddress);
		JobParameters.Add(ExportModeForTechnicalSupport);

		SetPrivilegedMode(True);
		ConfigurationSchemaData = ConfigurationSchema.SchemaBinaryData(False, False);
		JobParameters.Add(ConfigurationSchemaData);
		
		If TheFileIsBeingSaved And FileSystemExtensionAttached1 Then
			JobParameters.Add(Undefined);
		Else
			TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile("data2xml", "zip", 120);
			FilesCTL.LocATemporaryStorageFile(TemporaryStorageFileName, UUID);
			UploadFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);

			JobParameters.Add(UploadFileName);
		EndIf;

		UploadExtensionData = Not SaaSOperations.DataSeparationEnabled();
		JobParameters.Add(UploadExtensionData);
		
		ExportingParameters = New Structure;
		ExportingParameters.Insert(
			"UploadRegisteredChangesForExchangePlanNodes",
			UploadRegisteredChangesForExchangePlanNodes);
		ExportingParameters.Insert(
			"ThreadsCount",
			ExportDataJobsCount);
		ExportingParameters.Insert(
			"JobKind",
			Enums.ExportImportDataJobTypes.InteractiveDataExport);
		
		If InteractiveCallToCheckExportedDataIsSupported() Then
			ExportingParameters.Insert(
				"SkipCheckingExportedData",
				True);
		EndIf;
				
		StateID = New UUID();
		ExportingParameters.Insert("StateID", StateID);
			 
		StatusPresentation =  ExportImportDataClientServer.ExportImportDataAreaPreparationStateView(False) 
			+ Chars.LF 
			+ ExportImportDataClientServer.LongTermOperationHint();
			
		If TheFileIsBeingSaved And FileSystemExtensionAttached1 Then
			ExportPartAddress = PutToTempStorage(Undefined, UUID);
			ExportingParameters.Insert("ExportToClient", True);
		EndIf;
					
		ExportingParameters.Insert("ExportDataFromPlusExtensions", True);
		ExportingParameters.Insert("ClientSessionNumber", InfoBaseSessionNumber());
		
		JobParameters.Add(ExportingParameters);
		
		SetPrivilegedMode(False);
		
		Job = BackgroundJobs.Execute(NameOfDataUploadMethod,	JobParameters,,	
			NStr("vi = 'Chuẩn bị kết xuất vùng dữ liệu';
				|ru = 'Подготовка выгрузки области данных';
				|en = 'Preparing data area export'; fa = 'Preparing data area export';
				|it = 'Preparazione dell''upload dell''area dati';
				|pl = 'Przygotowanie przesyłania obszaru danych';
				|tr = 'Veri alanı dışa aktarma hazırlığı'"));
			
		JobID = Job.UUID;
		
		WriteLogEvent(
			NStr("vi = 'Kết xuất dữ liệu.Khởi động trực tác';
				|ru = 'Выгрузка данных.Интерактивный запуск';
				|en = 'Data export.Manual start'; fa = 'Data export.Manual start';
				|it = 'Выгрузка данных.Интерактивный запуск';
				|pl = 'Data export.Manual start';
				|tr = 'Veri dışa aktarımı.İnteraktif başlama'", Common.DefaultLanguageCode()),
			EventLogLevel.Information);
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		HandleError(ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise StrTemplate(
			DataUploadErrorDescriptionTemplate(), 
			ErrorProcessing.BriefErrorDescription(ErrorInfo));

	EndTry;
	
EndProcedure

&AtClient
Async Procedure CheckReadinessOfUnloading() 
	
	Begin = CurrentUniversalDateInMilliseconds();
	
	Try
		ExportState = ExportState(
			JobID,
			StateID,
			StorageAddress);
	Except
		
		ErrorInfo = ErrorInfo();
		
		HandleError(ErrorProcessing.DetailErrorDescription(ErrorInfo));
		ShowDataUploadError(ErrorInfo);
		
		Return;
		
	EndTry;
			
	If ExportState.StatusPresentation <> Undefined Then	
		StatusPresentation  = ExportState.StatusPresentation
			+ Chars.LF 
			+ ExportImportDataClientServer.LongTermOperationHint();
	EndIf;
						
	EndPercentage = ExportState.EndPercentage;
	Items.GroupEndPercentage.Visible = ExportState.EndPercentage <> Undefined; 
	
	If TheFileIsBeingSaved And FileSystemExtensionAttached1 Then
		For PartNumber = 1 To ExportState.PartCount Do
			BinaryData = GetPart(StateID);
			Await DataWriter.WriteAsync(BinaryData);
		EndDo;
	EndIf;
						
	If Not ExportState.Completed_ Then
		TimePassed = CurrentUniversalDateInMilliseconds() - Begin;
	   	AttachIdleHandler("CheckReadinessOfUnloading", Max(5 - TimePassed / 1000, 0.1), True);
		Return;
	EndIf;
		
	ProcessExportResultOnServer();

	If ValueIsFilled(TheTextOfTheWarningsOfDischarge) Then

		If TheFileIsBeingSaved Then
			QuestionTemplate = NStr("vi = 'Một phần dữ liệu chưa được kết xuất. Lưu quá trình kết xuất? 
				|
				|%1';
				|ru = 'Часть данных не выгружена. Сохранить выгрузку? 
				|
				|%1';
				|en = 'Some data is not exported. Do you want to save export? 
				|
				|%1'; fa = 'Some data is not exported. Do you want to save export? 
				|
				|%1';
				|it = 'Una parte dei dati non è stata caricata. Salvare l''upload?
				|
				|%1';
				|pl = 'Część danych nie została wyeksportowana. Czy zapisać plik eksportu? 
				|
				|%1';
				|tr = 'Verilerin bir kısmı dışa aktarılamadı. Dışa aktarma kaydedilsin mi? 
				|
				|%1'");
		Else
			QuestionTemplate = NStr("vi = 'Một phần dữ liệu chưa được kết xuất. Tiếp tục kết xuất? 
				|
				|%1';
				|ru = 'Часть данных не выгружена. Продолжить выгрузку? 
				|
				|%1';
				|en = 'Some data is not exported. Do you want to continue export? 
				|
				|%1'; fa = 'Some data is not exported. Do you want to continue export? 
				|
				|%1';
				|it = 'Una parte dei dati non è stata caricata. Continuare l''upload?
				|
				|%1';
				|pl = 'Część danych nie została wyeksportowana. Kontynuować eksportowanie? 
				|
				|%1';
				|tr = 'Verilerin bir kısmı dışa aktarılamadı. Dışa aktarma devam edilsin mi? 
				|
				|%1'");
		EndIf;
		
		CallbackDescriptionOnCompletion = New CallbackDescription(
			"SavingExportFileConfirmationCompletion",
			ThisObject);

		QueryText = StrTemplate(QuestionTemplate, TheTextOfTheWarningsOfDischarge);
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		QuestionParameters.Picture = PictureLib.Warning32;
		QuestionParameters.Title = NStr("vi = 'Một phần dữ liệu chưa được kết xuất';
										|ru = 'Часть данных не выгружена';
										|en = 'Some data is not exported'; fa = 'Some data is not exported';
										|it = 'Una parte dei dati non è stata caricata';
										|pl = 'Część danych nie została załadowana';
										|tr = 'Verilerin bir kısmı dışa aktarılamadı'");

		StandardSubsystemsClient.ShowQuestionToUser(
				CallbackDescriptionOnCompletion,
				QueryText,
				QuestionDialogMode.OKCancel,
				QuestionParameters);
				
	Else
		
		CompleteUpload();
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure SavingExportFileConfirmationCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> Undefined And QuestionResult.Value = DialogReturnCode.OK Then
		CompleteUpload();
	Else
		If TheFileIsBeingSaved Then
			If FileSystemExtensionAttached1 Then
				Await DataWriter.CloseAsync();
				Await DataWriter.TargetStream().CloseAsync();
				Await DeleteFilesAsync(FileNameAtClient);
			EndIf;
		EndIf;
		DeleteTemporaryDataAfterSaving();
		CloseOfCourse = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CompleteUpload()
	
	If TheFileIsBeingSaved Then
		If FileSystemExtensionAttached1 Then
			Await DataWriter.CloseAsync();
			Await DataWriter.TargetStream().CloseAsync();
			SetFileReceivedPage(Items.Pages.CurrentPage);
		Else
			SaveUploadFile();
		EndIf;
	Else
		StartDataTransfer(Items.Pages.CurrentPage);
	EndIf;
	
EndProcedure

&AtClient 
Procedure SaveUploadFile()
	
	FileNameAtClient = GetDataExportFileName(ExportModeForTechnicalSupport);
	
	If Not ValueIsFilled(DataExportedDataAddress) Then
		If UploadFileSize <= FilesCTLClientServer.AcceptableSizeOfTemporaryStorage() Then
			DataExportedDataAddress = MoveUploadDataFromFileToStorage(TemporaryStorageFileName,
				UUID);
		EndIf;
	EndIf;
	
	TransferParameters = FilesCTLClient.FileGettingParameters();
	If ValueIsFilled(DataExportedDataAddress) Then
		TransferParameters.FileNameOrAddress = DataExportedDataAddress;
	Else
		TransferParameters.FileNameOrAddress = TemporaryStorageFileName;
	EndIf;
	TransferParameters.CallbackDescriptionOnCompletion = New CallbackDescription("AfterSavingUploadFile", ThisObject);
	TransferParameters.BlockedForm = ThisObject;
	TransferParameters.TitleOfSaveDialog = NStr("vi = 'Nhận tệp kết xuất';
												|ru = 'Получение файла выгрузки';
												|en = 'Save export file'; fa = 'Save export file';
												|it = 'Ricezione del file di upload';
												|pl = 'Pobieranie pliku wyładowania';
												|tr = 'Dışa aktarma dosyasının alımı'");
	TransferParameters.FilterSaveDialog = StrTemplate(NStr("vi = 'Tệp nén %1';
															|ru = 'Архивы %1';
															|en = 'Archives %1'; fa = 'Archives %1';
															|it = 'Archivi %1';
															|pl = 'Archiwa %1';
															|tr = 'Arşivler %1'"), "(*.zip)|*.zip");
	TransferParameters.FileNameOfSaveDialog = FileNameAtClient;
	
	FilesCTLClient.GetFileInteractively(TransferParameters);
	
EndProcedure

&AtClient
Procedure AfterSavingUploadFile(FileDetails, AdditionalParameters) Export
	
	If FileDetails = Undefined Then
		
		Notification = New CallbackDescription("HandlingIssueOfFileReceiptError", ThisObject, AdditionalParameters);
		QueryText = StrTemplate(
			NStr("vi = 'Đã chuẩn bị tệp kết xuất, nhưng client chưa nhận được.%1Thử lưu lại?';
				|ru = 'Файл выгрузки подготовлен, но не получен клиентом.%1Повторить попытку сохранения?';
				|en = 'The export file is prepared but not received on the client.%1Do you want to try to save it again?'; fa = 'The export file is prepared but not received on the client.%1Do you want to try to save it again?';
				|it = 'File di upload preparato, ma non ricevuto dal cliente.%1Ripetere il tentativo di salvataggio?';
				|pl = 'Plik wyładowania jest gotowy, ale nie otrzymany przez klienta.%1Powtórzyć próbę zapisywania?';
				|tr = 'Dışa aktarma dosyası hazırlandı ancak istemci tarafından alınmadı.%1Tekrar kaydetmeyi denemek istiyor musunuz?'"),
			Chars.LF);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	DeleteTemporaryDataAfterSaving();
	
	CloseOfCourse = True;
	Close();
	
EndProcedure

&AtClient
Procedure HandlingIssueOfFileReceiptError(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		
		DeleteTemporaryDataAfterSaving();
		CloseOfCourse = True;
		Close();
		Return;
		
	EndIf; 
	
	SaveUploadFile();
	
EndProcedure

&AtServer
Procedure DeleteTemporaryDataAfterSaving()
	
	If Not ValueIsFilled(TemporaryStorageFileName) Then
		Return;
	EndIf;
	
	FilesCTL.DeleteTemporaryStorageFile(TemporaryStorageFileName);
	
EndProcedure

&AtClient
Procedure ShowDataUploadError(Val ErrorInfo)
	
	ErrorText = StrTemplate(
		NStr("vi = 'Khi kết xuất dữ liệu, đã xảy ra lỗi.
		|%1';
		|ru = 'При выгрузке данных произошла ошибка.
		|%1';
		|en = 'An error occurred while exporting data.
		|%1'; fa = 'An error occurred while exporting data.
		|%1';
		|it = 'Si è verificato un errore durante il caricamento dei file.
		|%1';
		|pl = 'Podczas eksportowania danych wystąpił błąd.
		|%1';
		|tr = 'Veriler dışa aktarılırken bir hata oluştu.
		|%1'"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	Items.WaitingPages.CurrentPage = Items.PageWaitingError;
	Items.Back.Enabled = True;

EndProcedure

&AtServerNoContext																	
Function ExportState(JobID, StateID, StorageAddress)
	
	ExportState = New Structure();
	ExportState.Insert("Completed_", False);
	ExportState.Insert("StatusPresentation", Undefined);
	ExportState.Insert("EndPercentage", Undefined);
			
	Job = BackgroundJobs.FindByUUID(JobID);
	
	JobActive = False;
			
	If Job = Undefined Then
		ExportResult = GetFromTempStorage(StorageAddress);
		If ExportResult = Undefined Then
			Raise(NStr("vi = 'Đã xảy ra lỗi khi chuẩn bị kết xuất - không tìm thấy nhiệm vụ chuẩn bị kết xuất nào.';
						|ru = 'При подготовке выгрузки произошла ошибка - не найдено задание подготавливающее выгрузку.';
						|en = 'An error occurred when preparing data for export. No export preparation job is found.'; fa = 'An error occurred when preparing data for export. No export preparation job is found.';
						|it = 'Durante la preparazione all''upload si è verificato un errore. Non è stato possibile trovare il task di preparazione all''upload.';
						|pl = 'Podczas przygotowywania przesyłania zaistniał błąd - nie znaleziono zadania przygotowującego przesyłanie.';
						|tr = 'Dışa aktarma hazırlanırken bir hata oluştu - boşaltmayı hazırlayan görev bulunamadı.'"));
		EndIf;
	Else
		
		If Job.State = BackgroundJobState.Active Then
			
			JobActive = True;
					
		ElsIf Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				Raise(ErrorProcessing.DetailErrorDescription(JobError));
			Else
				Raise(NStr("vi = 'Đã xảy ra lỗi khi chuẩn bị kết xuất - không tìm thấy nhiệm vụ chuẩn bị kết xuất nào.';
							|ru = 'При подготовке выгрузки произошла ошибка - не найдено задание подготавливающее выгрузку.';
							|en = 'An error occurred when preparing data for export. No export preparation job is found.'; fa = 'An error occurred when preparing data for export. No export preparation job is found.';
							|it = 'Durante la preparazione all''upload si è verificato un errore. Non è stato possibile trovare il task di preparazione all''upload.';
							|pl = 'Podczas przygotowywania przesyłania zaistniał błąd - nie znaleziono zadania przygotowującego przesyłanie.';
							|tr = 'Dışa aktarma hazırlanırken bir hata oluştu - boşaltmayı hazırlayan görev bulunamadı.'"));
			EndIf;
		ElsIf Job.State = BackgroundJobState.Canceled Then
			Raise(NStr("vi = 'Đã xảy ra lỗi khi chuẩn bị kết xuất - người quản trị đã hủy nhiệm vụ chuẩn bị kết xuất.';
						|ru = 'При подготовке выгрузки произошла ошибка - задание подготавливающее выгрузку было отменено администратором.';
						|en = 'An error occurred when preparing data for export. The export preparation job was canceled by the administrator.'; fa = 'An error occurred when preparing data for export. The export preparation job was canceled by the administrator.';
						|it = 'Durante la preparazione all''upload si è verificato un errore. Il task di preparazione all''upload è stato annullato dall''amministratore.';
						|pl = 'Podczas przygotowywania przesyłania zaistniał błąd - zadanie przygotowujące przesyłanie zostało anulowane przez administratora.';
						|tr = 'Dışa aktarma hazırlanırken bir hata oluştu - dışa aktarma görevi yönetici tarafından iptal edildi.'"));
		EndIf;
				
	EndIf;
	
 	ExportState.Completed_ = Not JobActive;
 					
	DataAreaExportImportState = ExportImportData.DataAreaExportImportState(
		StateID);	
				
	If ValueIsFilled(DataAreaExportImportState) Then
		ExportState.StatusPresentation = ExportImportData.DataAreaExportImportStateView(
			DataAreaExportImportState);
		ExportState.EndPercentage = ExportImportData.ExportImportDataAreaEndPercentage(
			DataAreaExportImportState);
	EndIf;
		
	If True Then
		Query = New Query;
		Query.SetParameter("Id", StateID);
		Query.Text =
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.ExportImportDataAreasParts AS ExportImportDataAreasParts
		|WHERE
		|	ExportImportDataAreasParts.Id = &Id";
		SetPrivilegedMode(True);
		ExportState.Insert("PartCount", Query.Execute().Unload()[0].Count);
		SetPrivilegedMode(False);
	EndIf;
		
	Return ExportState;

EndFunction

&AtServer
Procedure ProcessExportResultOnServer()
		
	ExportResult = GetFromTempStorage(StorageAddress);
	
	If ExportResult = Undefined Then
		Raise(NStr("vi = 'Khi kết xuất dữ liệu đã xảy ra lỗi - chưa tìm thấy kết quả kết xuất';
					|ru = 'При выгрузке данных произошла ошибка - не найден результат выгрузки';
					|en = 'An error occurred when exporting data. The export result is not found'; fa = 'An error occurred when exporting data. The export result is not found';
					|it = 'При выгрузке данных произошла ошибка - не найден результат выгрузки';
					|pl = 'An error occurred when exporting data. The export result is not found';
					|tr = 'Dışa aktarma hazırlanırken bir hata oluştu - dışa aktarma sonucu bulunamadı'"));
	EndIf;
			
	TheTextOfTheWarningsOfDischarge = "";	
		
	If TypeOf(ExportResult) = Type("String") Then
		UploadFileName = ExportResult;
	Else
		UploadFileName = ExportResult.FileName;
		If ValueIsFilled(ExportResult.Warnings) Then
			Separator = "
			|-----------------------------------------------
			|";
			
			TheTextOfTheWarningsOfDischarge = StrConcat(ExportResult.Warnings, Separator);
		EndIf;
	EndIf; 
	
	If Not TheFileIsBeingSaved Then
		FSObject = New File(UploadFileName);
		If Not FSObject.Exists() Or Not FSObject.IsFile() Then
			Raise(NStr("vi = 'Đã xảy ra lỗi khi chuẩn bị kết xuất - không tìm thấy tệp kết quả';
						|ru = 'При подготовке выгрузки произошла ошибка - не найден файл результата';
						|en = 'An error occurred when preparing data for export. The result file is not found'; fa = 'An error occurred when preparing data for export. The result file is not found';
						|it = 'Durante la preparazione di upload si è verificato un errore - non è stato trovato il file del risultato';
						|pl = 'Podczas przygotowania wyciągu wystąpił błąd - nie znaleziono pliku wyniku';
						|tr = 'Dışa aktarma hazırlanırken bir hata oluştu - sonuç dosyası buılunamadı'"));
		EndIf;
		UploadFileSize = FSObject.Size();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelPreparationTask(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	If Job = Undefined Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// Perhaps the task has just ended at this moment and there is no error
		WriteLogEvent(NStr("vi = 'Đã hủy nhiệm vụ chuẩn bị kết xuất vùng dữ liệu';
							|ru = 'Отмена выполнения задания подготовки выгрузки области данных';
							|en = 'Canceling data area export preparation job'; fa = 'Canceling data area export preparation job';
							|it = 'Annullare l''esecuzione del task di preparazione dell''upload dell''area dati';
							|pl = 'Anulowanie wykonywania zadania przygotowania przesyłania obszaru danych';
							|tr = 'Veri alanı dışa aktarma hazırlama görevini yürütmeyi iptal et'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure HandleError(Val DetailedPresentation)
	
	TextOfLREntry = StrTemplate(
		NStr("vi = 'Khi kết xuất dữ liệu, đã xảy ra lỗi:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------';
			 |ru = 'При выгрузке данных произошла ошибка:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------';
			 |en = 'An error occurred when exporting data:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------'; fa = 'An error occurred when exporting data:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------';
			 |it = 'Durante l''upload dei dati si è verificato un errore:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------';
			 |pl = 'Podczas przesyłania danych zaistniał błąd:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------';
			 |tr = 'Veriler dışa aktarılırken bir hata oluştu:
			 |
			 |-----------------------------------------
			 |%1
			 |-----------------------------------------'"), DetailedPresentation);
	
	WriteLogEvent(
		NStr("vi = 'Kết xuất dữ liệu';
			|ru = 'Выгрузка данных';
			|en = 'Exporting data'; fa = 'خروج داده';
			|it = 'Caricamento dei dati';
			|pl = 'Przesyłanie danych';
			|tr = 'Veri dışa aktarma'", Common.DefaultLanguageCode()),
		EventLogLevel.Error, , , TextOfLREntry);
		
EndProcedure

&AtServerNoContext
Function MoveUploadDataFromFileToStorage(TemporaryStorageFileName, FormIdentifier)

	FullFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
	Address = PutToTempStorage(New BinaryData(FullFileName), FormIdentifier);
	FilesCTL.DeleteTemporaryStorageFile(TemporaryStorageFileName);
	TemporaryStorageFileName = Undefined;
	
	Return Address;

EndFunction

&AtServerNoContext
Function GetDataExportFileName(Val IsExportModeForTechnicalSupport)
	
 	FileNameParts = New Array();
 	FileNameParts.Add("data_dump");
 	
 	If IsExportModeForTechnicalSupport Then
 		FileNameParts.Add("technical_support");
 	EndIf;
 	
 	AreaNumber = SaaSOperations.SessionSeparatorValue();
 	
 	If ValueIsFilled(AreaNumber) Then
 		FileNameParts.Add(Format(AreaNumber, "NG=0;"));
 	EndIf;
 	
 	FileNameParts.Add(TrimAll(AppTypesServer.CurrentAppTypeName()));
 	FileNameParts.Add(TrimAll(Metadata.Version));
 	
 	FileName = StrConcat(FileNameParts, "_") + ".zip";
 	
 	Return StringFunctions.LatinString(FileName);
 	
EndFunction 

#EndRegion 

#Region DataValidation

&AtServer
Procedure CheckingForPlusExtensions()
	PlusExtensions = New Map();
	ExportImportDataInternal.FillInInstalledPlusExtensions(PlusExtensions);
	PlusExtensionsInstalled = PlusExtensions.Count() > 0;
EndProcedure

&AtClient 
Procedure StartCheckingExportingData() Export
	
	If Not InteractiveCallToCheckExportedDataIsSupported() Then
		ExportingDataErrorsText = Undefined;
		CompleteVerificationOfExportedData();
		Return;
	EndIf;
	
	StartCheckingExportDataAtServer();
	
	Title = NStr("vi = 'Kiểm tra dữ liệu được kết xuất';
				|ru = 'Проверка выгружаемых данных';
				|en = 'Check the data to export'; fa = 'Check the data to export';
				|it = 'Проверка выгружаемых данных';
				|pl = 'Check the data to export';
				|tr = 'Dışa aktarılan verilerin kontrolü'");
	SetDefaultControls();
	Items.Back.Enabled = False;
	Items.Next.Visible = False;
	
	ShowWaitingState("StatePicture");
	Items.StatusText_3.Title = 
		NStr("vi = 'Đang kiểm tra dữ liệu được kết xuất. Thao tác này có thể mất nhiều thời gian.
				 |Vui lòng đợi...';
				 |ru = 'Выполняется проверка выгружаемых данных. Операция может занять длительное время.
				 |Пожалуйста, подождите...';
				 |en = 'Checking the data to export. It might take a long time.
				 |Please wait...'; fa = 'Checking the data to export. It might take a long time.
				 |Please wait...';
				 |it = 'Выполняется проверка выгружаемых данных. Операция может занять длительное время.
				 |Пожалуйста, подождите...';
				 |pl = 'Checking the data to export. It might take a long time.
				 |Please wait...';
				 |tr = 'Dışa aktarılan veriler kontrol ediliyor. İşlem uzun sürebilir.
				 |Lütfen bekleyin...'"); 
	Items.WaitingPageNextDescriptionTitle.Visible = False;	
	Items.Pages.CurrentPage = Items.PageWait;
	
	CheckIteration = 1;
	AttachIdleHandler("CheckEndVerificationOfExportedData", 5);
	
EndProcedure

&AtServer
Procedure StartCheckingExportDataAtServer()
	
	Try
		
		StorageAddress = PutToTempStorage(Undefined, UUID);
		DataValidationMethodName = "ExportImportData.PlaceErrorsOfExportedDataToTemporaryStorage";
		
		JobParameters = New Array;
		JobParameters.Add(StorageAddress);
			
		Job = BackgroundJobs.Execute(DataValidationMethodName,	JobParameters,,	
			NStr("vi = 'Kiểm tra dữ liệu được kết xuất';
				|ru = 'Проверка выгружаемых данных';
				|en = 'Check the data to export'; fa = 'Check the data to export';
				|it = 'Проверка выгружаемых данных';
				|pl = 'Check the data to export';
				|tr = 'Dışa aktarılan verilerin kontrolü'"));
			
		JobID = Job.UUID;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		ProcessErrorOfCheckingExportededData(
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Raise StrTemplate(
				NStr("vi = 'Khi kiểm tra dữ liệu được kết xuất đã xảy ra lỗi: %1.';
					|ru = 'При проверке выгружаемых данных произошла ошибка: %1.';
					|en = 'An error occurred when checking the data to export: %1.'; fa = 'An error occurred when checking the data to export: %1.';
					|it = 'При проверке выгружаемых данных произошла ошибка: %1.';
					|pl = 'An error occurred when checking the data to export: %1.';
					|tr = 'Dışa aktarılan verilerin kontrolü sırasında hata oluştu: %1.'") + Chars.LF + ErrorHint(),
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	EndTry;
	
EndProcedure

&AtServerNoContext
Function InteractiveCallToCheckExportedDataIsSupported()
	
	MinimumSupportingVersion = "2.0.11.5";
	Return CommonClientServer.CompareVersions(
		CloudTechnology.LibraryVersion(),
		MinimumSupportingVersion) >= 0;
	
EndFunction

&AtClient
Procedure CheckEndVerificationOfExportedData()
	
	Try
		CheckIsCompleted = ExportedDataVerificationComplete();
	Except
		
		ErrorInfo = ErrorInfo();
		
		DetachIdleHandler("CheckEndVerificationOfExportedData");
		
		ProcessErrorOfCheckingExportededData(
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
			
		ShowExportesDataCheckingError(ErrorInfo);
		
	EndTry;
	
	If CheckIsCompleted = True Then
		
		DetachIdleHandler("CheckEndVerificationOfExportedData");
	
		CompleteVerificationOfExportedData();
		
	Else
		
		CheckIteration = CheckIteration + 1;
		
		If CheckIteration = 3 Then
			DetachIdleHandler("CheckEndVerificationOfExportedData");
			AttachIdleHandler("CheckEndVerificationOfExportedData", 15);
		ElsIf CheckIteration = 4 Then
			DetachIdleHandler("CheckEndVerificationOfExportedData");
			AttachIdleHandler("CheckEndVerificationOfExportedData", 30);
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteVerificationOfExportedData()
	If ValueIsFilled(ExportingDataErrorsText) Then
		Title = NStr("vi = 'Đã tìm thấy lỗi trong dữ liệu được kết xuất';
					|ru = 'Обнаружены ошибки в выгружаемых данных';
					|en = 'Errors are found in the data to export'; fa = 'Errors are found in the data to export';
					|it = 'Обнаружены ошибки в выгружаемых данных';
					|pl = 'Errors are found in the data to export';
					|tr = 'Dışa aktarılan verilerde hatalar bulundu'");
		SetDefaultControls();
		Items.Back.Enabled = False;
		Items.Pages.CurrentPage = Items.ImportingDataErrorPage;
		Items.Next.Title = NStr("vi = 'Thử lại kiểm tra';
								|ru = 'Повторить проверку';
								|en = 'Check again'; fa = 'Check again';
								|it = 'Повторить проверку';
								|pl = 'Check again';
								|tr = 'Kontrolü yinele'");
	Else
		Items.Next.Title = NStr("vi = 'Tiếp theo';
								|ru = 'Далее';
								|en = 'Next'; fa = 'بعدی';
								|it = 'Далее';
								|pl = 'Next';
								|tr = 'İleri'");
		If TransitionMethod = MethodMigration() Then
			GoToAppMigrationForm();
		Else
			StartDataUpload();
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Procedure ProcessErrorOfCheckingExportededData(Val DetailedPresentation)
	
	GRRecordingTemplate = NStr("vi = 'Khi kiểm tra dữ liệu được kết xuất đã xảy ra lỗi:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------';
                           |ru = 'При проверке выгружаемых данных произошла ошибка:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------';
                           |en = 'An error occurred when checking the data to export:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------'; fa = 'An error occurred when checking the data to export:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------';
                           |it = 'При проверке выгружаемых данных произошла ошибка:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------';
                           |pl = 'An error occurred when checking the data to export:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------';
                           |tr = 'Dışa aktarılırken verilerin kontrolünde bir hata oluştu:
                           |
                           |-----------------------------------------
                           |%1
                           |-----------------------------------------'");
	TextOfLREntry = StrTemplate(GRRecordingTemplate, DetailedPresentation);
	
	WriteLogEvent(
		NStr("vi = 'Kiểm tra dữ liệu được kết xuất';
			|ru = 'Проверка выгружаемых данных';
			|en = 'Check the data to export'; fa = 'Check the data to export';
			|it = 'Проверка выгружаемых данных';
			|pl = 'Check the data to export';
			|tr = 'Dışa aktarılan verilerin kontrolü'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		TextOfLREntry);
		
EndProcedure

&AtClient
Procedure ShowExportesDataCheckingError(Val ErrorInfo)
	
	ErrorText = StrTemplate(
		NStr("vi = 'Khi kiểm tra dữ liệu được kết xuất đã xảy ra lỗi.
		|%1';
		|ru = 'При проверке выгружаемых данных произошла ошибка.
		|%1';
		|en = 'An error occurred when checking the data to export.
		|%1'; fa = 'An error occurred when checking the data to export.
		|%1';
		|it = 'При проверке выгружаемых данных произошла ошибка.
		|%1';
		|pl = 'An error occurred when checking the data to export.
		|%1';
		|tr = 'Dışa aktarılan verilerin kontrolü sırasında hata oluştu: 
		|%1.'"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	Items.WaitingPages.CurrentPage = Items.PageWaitingError;
	Items.Back.Enabled = True;

EndProcedure

&AtServer
Function ExportedDataVerificationComplete()
	
	Job = BackgroundJobs.FindByUUID(JobID);
			
	If Job = Undefined Then
		DataUploadErrors = GetFromTempStorage(StorageAddress);
		If DataUploadErrors = Undefined Then
			Raise(NStr("vi = 'Khi thực hiện kiểm tra dữ liệu được kết xuất đã xảy ra lỗi - không tìm thấy nhiệm vụ thực hiện kiểm tra.';
						|ru = 'При выполнении проверки выгружаемых данных произошла ошибка - не найдено задание выполняющее проверку.';
						|en = 'An error occurred when checking data to export. No job to perform the check is found.'; fa = 'An error occurred when checking data to export. No job to perform the check is found.';
						|it = 'При выполнении проверки выгружаемых данных произошла ошибка - не найдено задание выполняющее проверку.';
						|pl = 'An error occurred when checking data to export. No job to perform the check is found.';
						|tr = 'Dışa aktarılan veriler kontrol edilirken bir hata oluştu - kontrolü gerçekleştiren görev bulunamadı.'"));
		EndIf;
	Else
		
		If Job.State = BackgroundJobState.Active Then
			Return False;
		ElsIf Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				Raise(ErrorProcessing.DetailErrorDescription(JobError));
			Else
				Raise(NStr("vi = 'Khi kiểm tra dữ liệu được kết xuất đã xảy ra lỗi - nhiệm vụ mà thực hiện kiểm tra đã kết thúc với lỗi không xác định.';
							|ru = 'При проверке выгружаемых данных произошла ошибка - задание выполняющие проверку завершилось с неизвестной ошибкой.';
							|en = 'An error occurred when checking the data to export. The job executing the check was completed with an unknown error.'; fa = 'An error occurred when checking the data to export. The job executing the check was completed with an unknown error.';
							|it = 'При проверке выгружаемых данных произошла ошибка - задание выполняющие проверку завершилось с неизвестной ошибкой.';
							|pl = 'An error occurred when checking the data to export. The job executing the check was completed with an unknown error.';
							|tr = 'Dışa aktarılan veriler doğrulanırken bir hata oluştu - doğrulamayı gerçekleştiren görev bilinmeyen bir hatayla sona erdi.'"));
			EndIf;
		ElsIf Job.State = BackgroundJobState.Canceled Then
			Raise(NStr("vi = 'Khi kiểm tra dữ liệu được kết xuất đã xảy ra lỗi - nhiệm vụ mà thực hiện kiểm tra đã bị hủy bỏ bởi người quản trị.';
						|ru = 'При проверке выгружаемых данных произошла ошибка - задание выполняющие проверку было отменено администратором.';
						|en = 'An error occurred when checking the data to export. The job executing the check was canceled by the administrator.'; fa = 'An error occurred when checking the data to export. The job executing the check was canceled by the administrator.';
						|it = 'При проверке выгружаемых данных произошла ошибка - задание выполняющие проверку было отменено администратором.';
						|pl = 'An error occurred when checking the data to export. The job executing the check was canceled by the administrator.';
						|tr = 'Dışa aktarılan kontrol edilirken bir hata oluştu - kontrolü gerçekleştiren görev yönetici tarafından iptal edildi.'"));
		EndIf;
		
		DataUploadErrors = GetFromTempStorage(StorageAddress);
		
	EndIf;
	
	PartsOfErrorText = New Array;
	For Each DataUploadError In DataUploadErrors Do
		PartsOfErrorText.Add("● ");
		PartsOfErrorText.Add(DataUploadError);
		PartsOfErrorText.Add(Chars.LF);
	EndDo;
	ExportingDataErrorsText = StrConcat(PartsOfErrorText);
		
	JobID = Undefined;
	Return True;

EndFunction

&AtClient
Procedure CheckPlusExtensions()
	QueryOptions = New Structure;
	QueryOptions.Insert("HandlerResults_1", "Attachable_CheckPlusExtensions");
	QueryOptions.Insert("Key", UUID);
	HandlerResults_1 = QueryOptions.HandlerResults_1;
	
	StartCheckingPlusExtensions(QueryOptions, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = NStr("vi = 'Kiểm tra phần mở rộng';
									|ru = 'Проверка расширений';
									|en = 'Check extensions'; fa = 'Check extensions';
									|it = 'Проверка расширений';
									|pl = 'Check extensions';
									|tr = 'Uzantı kontrolü'");
	IdleParameters.StateDescription = NStr("vi = 'Đang kiểm tra số tiền kiểm soát phần mở rộng 1C:Plus...';
											|ru = 'Выполняется проверка контрольных сумм расширений 1С:Плюс...';
											|en = 'Checking checksums of 1C:Plus extensions...'; fa = 'Checking checksums of 1C:Plus extensions...';
											|it = 'Выполняется проверка контрольных сумм расширений 1С:Плюс...';
											|pl = 'Checking checksums of 1C:Plus extensions...';
											|tr = '1C:Plus eklentilerinin sağlanma toplamları kontrol ediliyor...'");
	IdleParameters.AcceptableWaitingTime = 5;
	SetWaitingPage(Items.Pages.CurrentPage, IdleParameters);
EndProcedure

&AtServerNoContext
Procedure StartCheckingPlusExtensions(QueryOptions, StorageAddress, JobID)
	
	StartBackgroundJobOnServer("CheckPlusExtensions", 
		QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Async Procedure Attachable_CheckPlusExtensions(Result, AdditionalParameters) Export	
	If Result.Property("Data") And TypeOf(Result.Data) = Type("Array") And Result.Data.Count() > 0 Then
		QuestionRows = New Array;
		QuestionRows.Add(NStr("vi = 'Đã tìm thấy sự khác nhau trong các phần mở rộng 1C:Plus so với bản gốc:';
								|ru = 'Обнаружены отличия в расширениях 1С:Плюс от исходных:';
								|en = 'Differences from the original extensions are found in 1C:Plus'; fa = 'Differences from the original extensions are found in 1C:Plus';
								|it = 'Обнаружены отличия в расширениях 1С:Плюс от исходных:';
								|pl = 'Differences from the original extensions are found in 1C:Plus';
								|tr = '1C:Plus eklentilerinde orijinal eklentilerinden farklılıklar tespit edilir:'"));
		For Each Extension In Result.Data Do
			QuestionRows.Add(StrTemplate(NStr("vi = '● %1 phiên bản %2';
												|ru = '● %1 версия %2';
												|en = '● %1 version %2'; fa = '● %1 version %2';
												|it = '● %1 версия %2';
												|pl = '● %1 version %2';
												|tr = '● %1 sürüm %2'"), Extension.Name, Extension.Version));
		EndDo;
		QuestionRows.Add("");
		QuestionRows.Add(NStr("vi = 'Khi kết nhập vào dịch vụ, sẽ thay thế các phần mở rộng này sang phiên bản gốc';
								|ru = 'При загрузке в сервис эти расширения будут заменены на исходные версии';
								|en = 'When you import these extensions to the service, they will be replaced with the original versions'; fa = 'When you import these extensions to the service, they will be replaced with the original versions';
								|it = 'При загрузке в сервис эти расширения будут заменены на исходные версии';
								|pl = 'When you import these extensions to the service, they will be replaced with the original versions';
								|tr = 'Bu eklentiler hizmete yüklendiğinde orijinal halleriyle değiştirilecektir'"));
		
		Await DoQueryBoxAsync(StrConcat(QuestionRows, Chars.LF), QuestionDialogMode.OK);
	EndIf;
	
	PlusVerificationCompleted = True;
	
	SetWelcomePage(Items.Pages.CurrentPage);
	GoNext(Items.Pages.CurrentPage);
EndProcedure

#EndRegion

#Region TrafficHandling

&AtClient
Procedure GoNext(CurrentPage)
	
	If CurrentPage = Items.PageGreeting And CheckFilling() Then
		If Not PlusVerificationCompleted And PlusExtensionsInstalled Then
			CheckPlusExtensions();
		ElsIf TransitionMethod = MethodFile() Then
			SetDataUploadPage(Items.Pages.CurrentPage, True);
		Else
			SetLoginPage(CurrentPage);
		EndIf; 
	ElsIf CurrentPage = Items.LoginPage And CheckFilling() Then
		StartLoggingInToService(CurrentPage);
		
	ElsIf CurrentPage = Items.SelectRegistrationOptionPage And CheckFilling() Then
		SetEnterDetailsPage(CurrentPage);
		
	ElsIf CurrentPage = Items.EnterInformationPage And CheckFilling() Then
		StartRegisteringInService(CurrentPage);
		
	ElsIf CurrentPage = Items.EnterActivationCodePage Then
		SetLoginPage(CurrentPage);
		
	ElsIf CurrentPage = Items.PageSelectingTheTransitionMethod And CheckFilling() Then
		If Not CheckIfYouCanAutomaticallyNavigateWithExtensions() Then
			SetTransitionMethodPage(CurrentPage);
		ElsIf IBUsers.Count() > 0 And RecoveryExtensions.Count() = 0 Then
			StartMatchingUsers(CurrentPage);
		ElsIf TransitionMethod = MethodMigration() And RecoveryExtensions.Count() = 0 Then
			StartCheckingExportingData();
		ElsIf RecoveryExtensions.Count() > 0 Then 
			StartExtensionsMatching(CurrentPage);
		Else			
			SetDataUploadPage(CurrentPage, False);
		EndIf;
	
	ElsIf CurrentPage = Items.ExtensionsPage And CheckFilling() 
		And CheckExtensionsForRecoveryCompletion() Then
		If IBUsers.Count() > 0 Then
			StartMatchingUsers(CurrentPage);
		ElsIf TransitionMethod = MethodMigration() Then
			StartCheckingExportingData()
		Else			
			SetDataUploadPage(CurrentPage, False);
		EndIf;
			
	ElsIf CurrentPage = Items.UsersMappingPage And CheckFilling() Then
		If TransitionMethod = MethodMigration() Then
			StartCheckingExportingData();
		Else			
			SetDataUploadPage(CurrentPage, False);
		EndIf;

	ElsIf CurrentPage = Items.DataUploadPage Then
		StartUploadingData();
		
	ElsIf CurrentPage = Items.PageCompletion Then
		CloseOfCourse = True;
		Close();
		
	ElsIf CurrentPage = Items.PageFileReceived Then
		CloseOfCourse = True;
		Close();
		
	ElsIf CurrentPage = Items.PageFileExtensionIsNotEnabled Then
		CloseOfCourse = True;
		Close();
		
	ElsIf CurrentPage = Items.ExtensionWarningPage
		Or CurrentPage = Items.ImportingDataErrorPage Then
		StartCheckingExportingData();			
	EndIf;
	
EndProcedure

&AtClient
Procedure GoBack_(CurrentPage)
	
	Items.Back.Visible = True;
	If CurrentPage = Items.SelectRegistrationOptionPage Then
		SetLoginPage(CurrentPage);
		
	ElsIf CurrentPage = Items.EnterInformationPage Then
		If CheckInOption = OptionRequestForRegistration()  Then
			SetLoginPage(CurrentPage);
		Else
			SetSelectRegistrationOptionPage(CurrentPage);
		EndIf; 
		
	ElsIf CurrentPage = Items.LoginPage Then
		SetWelcomePage(CurrentPage);
		
	ElsIf CurrentPage = Items.PageWait Then
		If TransitionMethod = MethodFile() Then
			CurrentPage = Items.PageGreeting;
			SetDataUploadPage(CurrentPage, True);
		ElsIf TheNameOfThePageThatGoesToTheUploadPage = Items.PageSelectingTheTransitionMethod.Name Then
			CurrentPage = Items.PageSelectingTheTransitionMethod;
			SetDataUploadPage(CurrentPage, True);
		ElsIf Not RegistrationWasPerformed Then
			SetLoginPage(CurrentPage);
		Else
			SetEnterDetailsPage(CurrentPage);
		EndIf;
		Items.WaitingPages.CurrentPage = Items.PageDescriptionOfWaiting;
		
	ElsIf CurrentPage = Items.PageSelectingTheTransitionMethod Then
		SetLoginPage(CurrentPage);
	
	ElsIf CurrentPage = Items.ExtensionsPage Then
		SetTransitionMethodPage(CurrentPage);
		
	ElsIf CurrentPage = Items.UsersMappingPage Then
		If TransitionMethod = MethodMigration() And RecoveryExtensions.Count() > 0 Then
			SetExtensionsMappingPage(CurrentPage);
		Else
			SetTransitionMethodPage(CurrentPage);
		EndIf;
		
	ElsIf CurrentPage = Items.DataUploadPage Then
		If TheFileIsBeingSaved Then
			If TheNameOfThePageThatGoesToTheUploadPage = Items.PageGreeting.Name Then
				SetWelcomePage(CurrentPage);
			Else
				SetTransitionMethodPage(CurrentPage);
			EndIf;
		ElsIf IBUsers.Count() > 0 Then
			SetUserMappingPage(CurrentPage);
		Else
			SetTransitionMethodPage(CurrentPage);
		EndIf;
		
	ElsIf CurrentPage = Items.EnterActivationCodePage Then
		SetLoginPage(CurrentPage);
		
	ElsIf CurrentPage = Items.ExtensionWarningPage Then
		SetDataUploadPage(CurrentPage, False);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure SetDefaultControls()
	
	Items.Next.Title = NStr("vi = 'Tiếp theo';
							|ru = 'Далее';
							|en = 'Next'; fa = 'بعدی';
							|it = 'Avanti';
							|pl = 'Dalej';
							|tr = 'İleri'");
	Items.Next.Visible = True;
	Items.Next.Enabled = True;
	
	Items.Back.Title = NStr("vi = '< Quay lại';
							|ru = '< Назад';
							|en = '< Back'; fa = '< بازگشت';
							|it = '< Indietro';
							|pl = '< Wróć';
							|tr = '< Geri'");
	Items.Back.Visible = True;
	Items.Back.Enabled = True;
	
EndProcedure

&AtClient
Procedure SetWelcomePage(CurrentPage)
	
	Title = GreetingTitle;
	SetDefaultControls();
	
	Items.Back.Visible = False;
	If TransitionMethod = MethodMigration() Then
		TransitionMethod = ?(ValueIsFilled(ServiceAddress), UploadMethod(), MethodFile());
		WhenChangingTransitionMethod();
	EndIf; 
	
	CurrentPage = Items.PageGreeting;
	
EndProcedure

&AtClient
Procedure SetLoginPage(CurrentPage)
	
	Title = EntryHeader();
	SetDefaultControls();
	Items.Next.Title = NStr("vi = 'Nhập';
							|ru = 'Войти';
							|en = 'Log in'; fa = 'Log in';
							|it = 'Accedere';
							|pl = 'Log in';
							|tr = 'Giriş'");
	
	CurrentPage = Items.LoginPage;

EndProcedure

&AtClient
Procedure SetSelectRegistrationOptionPage(CurrentPage)
	
	If NumberOfServiceOrganizations = 0 Then
		Title = NStr("vi = 'Bước đăng ký 1/2: Chọn một phương án';
					|ru = 'Шаг регистрации 1 из 2: Выбор варианта';
					|en = 'Registration step 1 out of 2: Selecting option'; fa = 'Registration step 1 out of 2: Selecting option';
					|it = 'Passaggio 1 di 2 della registrazione: Selezione dell''opzione';
					|pl = 'Krok rejestracji 1 z 2: Wybór wariantu';
					|tr = 'Kayıt adımı 1/2: Seçenek seçimi'");
		Items.ToChooseTheOrganizationTitle.Visible = False;
		Items.TheTitleToEnterTheActivationCode.Visible = False;
		Items.PickUpTheOOAutomatically.TitleLocation = FormItemTitleLocation.Top;
		Items.PickUpTheOOAutomatically.ChoiceList[0].Presentation = NStr("vi = 'Bắt đầu đăng ký mới';
																		|ru = 'Начать новую регистрацию';
																		|en = 'Start new registration'; fa = 'Start new registration';
																		|it = 'Iniziare una nuova registrazione';
																		|pl = 'Zacznij nową rejestrację';
																		|tr = 'Yeni kayıt başlat'"); 
	Else
		Title = NStr("vi = 'Bước đăng ký 1/2: Chọn doanh nghiệp';
					|ru = 'Шаг регистрации 1 из 2: Выбор организации';
					|en = 'Registration step 1 out of 2: Selecting service provider'; fa = 'Registration step 1 out of 2: Selecting service provider';
					|it = 'Passaggio 1 di 2 della registrazione: Selezionare l''azienda';
					|pl = 'Krok rejestracji 1 z 2: Wybór firmy';
					|tr = 'Kayıt adımı 1/2: İş yeri seçimi'");
		Items.ToChooseTheOrganizationTitle.Visible = True;
		Items.TheTitleToEnterTheActivationCode.Visible = True;
		Items.PickUpTheOOAutomatically.TitleLocation = FormItemTitleLocation.None;
		Items.PickUpTheOOAutomatically.ChoiceList[0].Presentation = 
			NStr("vi = 'Tự động chọn một doanh nghiệp dịch vụ';
				|ru = 'Подобрать обслуживающую организацию автоматически';
				|en = 'Pick service provider automatically'; fa = 'Pick service provider automatically';
				|it = 'Selezionare l''azienda di servizio automaticamente';
				|pl = 'Wybierz firmę obsługującą automatycznie';
				|tr = 'Hizmet veren iş yerini otomatik seçmek'"); 
	EndIf;
	ActivationCode = Undefined;
	SetDefaultControls();
	Items.TheSelectGroupOO.Visible = Not (NumberOfServiceOrganizations = 0);
	CurrentPage = Items.SelectRegistrationOptionPage;

EndProcedure
 
&AtClient
Procedure SetEnterDetailsPage(CurrentPage)
	
	If CheckInOption = OptionRequestForRegistration() Then
		Title = NStr("vi = 'Bước đăng ký 1/2: Nhập thông tin';
					|ru = 'Шаг регистрации 1 из 2: Ввод сведений';
					|en = 'Registration step 1 out of 2: Entering information'; fa = 'Registration step 1 out of 2: Entering information';
					|it = 'Passaggio 1 di 2 della registrazione: Inserimento dati';
					|pl = 'Krok rejestracji 1 z 2: Wprowadzenie danych';
					|tr = 'Kayıt adımı 1/2: Bilgi girişi'") 
	Else
		Title = NStr("vi = 'Bước đăng ký 2/2: Nhập thông tin';
					|ru = 'Шаг регистрации 2 из 2: Ввод сведений';
					|en = 'Registration step 2 out of 2: Entering information'; fa = 'Registration step 2 out of 2: Entering information';
					|it = 'Passaggio 2 di 2 della registrazione: Inserimento dati';
					|pl = 'Krok rejestracji 2 z 2: Wprowadzenie danych';
					|tr = 'Kayıt adımı 2/2: Bilgi girişi'");
	EndIf;
	
	SetDefaultControls();
	Items.Next.Title = NStr("vi = 'Đăng ký';
							|ru = 'Зарегистрироваться';
							|en = 'Register'; fa = 'ثبات';
							|it = 'Registrarsi';
							|pl = 'Register';
							|tr = 'Kayıt ol'");
	
	If CheckInOption = OptionRequestForRegistration() Then
		Items.RegistrationOptionInformation.CurrentPage = Items.OrganizationInformationPage;
		Items.DataOfTheSelectedOrganization.Title = SupportContactLine();
	ElsIf CheckInOption = OptionEnterActivationCode() Then
		Items.RegistrationOptionInformation.CurrentPage = Items.ActivationCodePage;
		CheckActivationCode();
	Else
		Items.RegistrationOptionInformation.CurrentPage = Items.OrganizationInformationPage;
		If CheckInOption = OptionOoSelection() Then
			SelectionDataHeader = ServiceOrganizationContactLine();
		ElsIf CheckInOption = OptionRequestForRegistration() Then
			SelectionDataHeader = SupportContactLine();
		Else
			SelectionDataHeader = ?(NumberOfServiceOrganizations = 0, 
				SupportContactLine(), OrganizationAutoSelectionLine());
		EndIf; 
		Items.DataOfTheSelectedOrganization.Title = SelectionDataHeader;
	EndIf;
	
	Items.ActivationCode.Visible = (CheckInOption = OptionEnterActivationCode());
	Items.RegistrationMail.ReadOnly = (CheckInOption = OptionEnterActivationCode());
	CurrentPage = Items.EnterInformationPage;
	
	If CheckInOption = OptionEnterActivationCode() Then
		CurrentItem = Items.ActivationCode;
	EndIf; 
	
	ShowFillInFlag(RegistrationName, Items.CheckingTheName.Name);
	CheckEmailAddress();
	ShowFillInFlag(RegistrationPhone, Items.CheckingYourPhone.Name);
	
EndProcedure

&AtClient
Procedure SetPageEnterActivationCode(CurrentPage)
	
	Title = NStr("vi = 'Bước đăng ký 2/2: Nhập mã kích hoạt';
				|ru = 'Шаг регистрации 2 из 2: Ввод кода активации';
				|en = 'Registration step 2 out of 2: Entering activation code'; fa = 'Registration step 2 out of 2: Entering activation code';
				|it = 'Passaggio 2 di 2 della registrazione: Inserimento codice attivazione';
				|pl = 'Krok rejestracji 2 z 2: Wprowadzenie kodu aktywacji';
				|tr = 'Kayıt adımı 2/2: Aktivasyon kodunun girişi'");
	SetDefaultControls();

	CurrentPage = Items.EnterActivationCodePage;
	
EndProcedure
 
&AtClient
Procedure SetWaitingPage(CurrentPage, IdleParameters)
	
	Title = IdleParameters.PageHeader;
	If TheFileIsBeingSaved Then
		Items.WaitingPageNextDescriptionTitle.Visible = False;
	Else
		Items.WaitingPageNextDescriptionTitle.Visible = IdleParameters.DisplayDescriptionTitle;
	EndIf;
	
	Items.WaitingPageDescription.Title = IdleParameters.DescriptionOfWaiting;
	
	Items.StatusPresentation.Visible = False;
	Items.StatusText_3.Visible = True;
	Items.StatusText_3.Title = Chars.LF + IdleParameters.StateDescription;
	
	SetDefaultControls();
	Items.Next.Visible = False;
	Items.Back.Enabled = False;
	
	ShowWaitingState("StatePicture");
	
	CurrentPage = Items.PageWait;
	WaitingCounter = 0;
	AcceptableWaitingTime = IdleParameters.AcceptableWaitingTime;
	CheckQueryResult();
	
EndProcedure

&AtClient
Procedure SetTransitionMethodPage(CurrentPage)
	
	If DataSeparationEnabled Then
		TitleTemplate1 = NStr("vi = 'Bước 2/%1: Chọn phương pháp chuyển';
								|ru = 'Шаг 2 из %1: Выбор способа переноса';
								|en = 'Step 2 out of %1: Selecting transfer method'; fa = 'Step 2 out of %1: Selecting transfer method';
								|it = 'Passaggio 2 di %1: Inserimento metodo di trasferimento';
								|pl = 'Krok 2 z %1: Wybór sposobu przeniesienia';
								|tr = '%1 adımından 2. adım: Taşıma yöntemini seçin'");
	Else
		TitleTemplate1 = NStr("vi = 'Bước 2/%1: Chọn phương pháp chuyển';
								|ru = 'Шаг 2 из %1: Выбор способа перехода';
								|en = 'Step 2 out of %1: Selecting migration method'; fa = 'Step 2 out of %1: Selecting migration method';
								|it = 'Passaggio 2 di %1: Inserimento metodo di passaggio';
								|pl = 'Krok 2 z %1: Wybór sposobu przejścia';
								|tr = '%1 adımından 2. adım: Geçiş yöntemini seçin'");
	EndIf;
	
	Title = StrTemplate(TitleTemplate1, TotalWizardSteps());
	SetDefaultControls();
	If MigrationIsAvailable Or UploadIsAvailable Then
		Items.Next.Enabled = True;
		If TransitionMethod = -1 Then
			TransitionMethod = UploadMethod();
		EndIf;
	Else 
		Items.Next.Enabled = False;
		TransitionMethod = -1;
	EndIf;
	
	CurrentPage = Items.PageSelectingTheTransitionMethod;
	
EndProcedure

&AtClient
Procedure SetUserMappingPage(CurrentPage)
	
	Title = HeaderMatchingUsers();
	CurrentPage = Items.UsersMappingPage;
	SetDefaultControls();
	Items.Next.Title = NStr("vi = 'Tiếp tục';
							|ru = 'Продолжить';
							|en = 'Continue'; fa = 'ادامه';
							|it = 'Continuare';
							|pl = 'Kontynuuj';
							|tr = 'Devam'");
	
EndProcedure


&AtClient
Procedure SetExtensionsMappingPage(CurrentPage)
	
	Title = TitleExtensionsMatching();
	CurrentPage = Items.ExtensionsPage;
	SetDefaultControls();
	Items.Next.Title = NStr("vi = 'Tiếp tục';
							|ru = 'Продолжить';
							|en = 'Continue'; fa = 'ادامه';
							|it = 'Продолжить';
							|pl = 'Kontynuuj';
							|tr = 'Devam'");
	
EndProcedure

&AtClient 
Procedure SetDataUploadPage(CurrentPage, ThisIsSavingFile)
	
	TheFileIsBeingSaved = ThisIsSavingFile;
	TheNameOfThePageThatGoesToTheUploadPage = CurrentPage.Name;
	
	Title = HeaderUploadingData();
	Items.GroupNameOfTheApplication.Visible = Not TheFileIsBeingSaved;
	
	CurrentPage = Items.DataUploadPage;
	SetDefaultControls();
	Items.Next.Title = ?(TheFileIsBeingSaved, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"), NStr("vi = 'Kết xuất dữ liệu';
																			|ru = 'Выгрузить данные';
																			|en = 'Export data'; fa = 'خروج اطلاعات داده';
																			|it = 'Carica i dati';
																			|pl = 'Prześlij dane';
																			|tr = 'Verileri dışa aktar'"));
	
EndProcedure

&AtClient
Procedure SetPageCompletion(CurrentPage)
	
	Title = NStr("vi = 'Hoàn thành kết xuất';
				|ru = 'Выгрузка завершена';
				|en = 'Export completed'; fa = 'Export completed';
				|it = 'Upload completato';
				|pl = 'Eksportowanie zostało zakończone';
				|tr = 'Dışa aktarma tamamlandı'");
	CurrentPage = Items.PageCompletion;
	SetDefaultControls();
	
	Items.Next.Title = NStr("vi = 'Kết thúc';
							|ru = 'Завершить';
							|en = 'Complete'; fa = 'تکمیل';
							|it = 'Completare';
							|pl = 'Complete';
							|tr = 'Tamamla'");
    Items.Back.Visible = False;
	
EndProcedure

&AtClient
Procedure SetExtensionWarningPage(CurrentPage)
	
	Title = NStr("vi = 'Tiện ích mở rộng cấu hình đang hoạt động để thay đổi cấu trúc dữ liệu';
				|ru = 'Активны расширения конфигурации, изменяющие структуру данных';
				|en = 'Configuration extensions that change the data structure are active'; fa = 'Configuration extensions that change the data structure are active';
				|it = 'Le estensioni di configurazione che modificano la struttura dei dati sono abilitate';
				|pl = 'Aktywne rozszerzenia konfiguracji, zmieniające strukturę danych';
				|tr = 'Veri yapısını değiştiren konfigürasyon uzantıları etkin durumda'");
	CurrentPage = Items.ExtensionWarningPage;
	SetDefaultControls();
	
	Items.DecorationAverage.Visible = DataSeparationEnabled;
	Items.Next.Title = NStr("vi = 'Đồng ý';
							|ru = 'ОК';
							|en = 'OK'; fa = 'تأیید';
							|it = 'OK';
							|pl = 'OK';
							|tr = 'Tamam'");	
	
EndProcedure

&AtClient
Procedure SetFileReceivedPage(CurrentPage)
	
	Title = NStr("vi = 'Hoàn thành kết xuất';
				|ru = 'Выгрузка завершена';
				|en = 'Export completed'; fa = 'Export completed';
				|it = 'Upload completato';
				|pl = 'Eksportowanie zostało zakończone';
				|tr = 'Dışa aktarma tamamlandı'");
	CurrentPage = Items.PageFileReceived;
	SetDefaultControls();
	
	Items.Next.Title = NStr("vi = 'Kết thúc';
							|ru = 'Завершить';
							|en = 'Exit'; fa = 'خروج';
							|it = 'Завершить';
							|pl = 'Exit';
							|tr = 'Tamamla'");
    Items.Back.Visible = False;
	Items.Cancel.Visible = False;
	
EndProcedure

&AtClient
Procedure SetPageFileExtensionIsNotEnabled(CurrentPage)
	
	Title = NStr("vi = 'Đã hủy kết xuất';
				|ru = 'Выгрузка отменена';
				|en = 'Export canceled'; fa = 'Export canceled';
				|it = 'Выгрузка отменена';
				|pl = 'Export canceled';
				|tr = 'Dışa aktarma iptal edildi'");
	CurrentPage = Items.PageFileExtensionIsNotEnabled;
	SetDefaultControls();
	
	Items.Next.Title = NStr("vi = 'Kết thúc';
							|ru = 'Завершить';
							|en = 'Exit'; fa = 'خروج';
							|it = 'Завершить';
							|pl = 'Exit';
							|tr = 'Tamamla'");
    Items.Back.Visible = False;
	Items.Cancel.Visible = False;
	
EndProcedure

&AtClient
Procedure GoToAppMigrationForm()
	
	FormOfMigration = GetForm("DataProcessor.WizardOfTransitionToCloud.Form.ApplicationMigration");
	FormOfMigration.SoftwareInterfaceVersion = SoftwareInterfaceVersion;
	
	AddressParts = StrSplit(Lower(TrimAll(ServiceAddress)), "/", False);
	Protocol = AddressParts[0];
	If StrEndsWith(Protocol, ":") Then
		AddressParts.Delete(0);
	EndIf;
	ServerName = AddressParts[0];
	
	FormOfMigration.ServiceAddress = "https://" + ServerName;
	FormOfMigration.Login = Login;
	FormOfMigration.Password = Password;
	FormOfMigration.SubscriberCode = SubscriberCode;
	FormOfMigration.APIAddress = APIAddress;
	FormOfMigration.RegistrationAddress = RegistrationAddress;
	FormOfMigration.RecoveryAddress = RecoveryAddress;
	FormOfMigration.RegistrationAllowed = RegistrationRequestAvailable;
	FormOfMigration.RegistrationInServiceState = "Registered";
	FormOfMigration.Items.Back.Visible = False;
	FormOfMigration.StepsCount = TotalWizardSteps();
	
	OwnerRole = "Owner";
	UserRole_ = "User";
	MigrationUserRights = FormOfMigration.UsersRights; // ValueTable
	
	If UsersRights.Count() > 0 Then
		For Each String In UsersRights Do
			If ValueIsFilled(String.Login) Then
				NewRow = MigrationUserRights.Add();
				NewRow.Login = String.Login;
				NewRow.Description = String.FullName;
				NewRow.User = String.User;
				NewRow.Right = PresentationOfUserRights(String.Right);
				NewRow.Email = String.Email;
				NewRow.Role = ?(String.ThisIsTheSubscriberOwner, OwnerRole, UserRole_);
			EndIf;
		EndDo;
	Else
		NewRow = MigrationUserRights.Add();
		NewRow.Login = Login;
		NewRow.Description = SubscriberName_3;
		NewRow.Right = PresentationOfUserRights(LaunchAndAdministrationRights());
		NewRow.Role = OwnerRole; 
	EndIf;
		
	For Each StringExtension In RecoveryExtensions Do
		If Not StringExtension.Refresh Then
			Continue;
		EndIf;
		NewRow = FormOfMigration.RecoveryExtensions.Add();
		NewRow.Name = StringExtension.UseExtensionName;
		NewRow.Version = StringExtension.Version;
	EndDo;
	
	CloseOfCourse = True;
	Close();
	FormOfMigration.Open();
	FormOfMigration.Items.Pages.CurrentPage = FormOfMigration.Items.CreateApplicationPage;

EndProcedure

&AtClient
Function EntryHeader()
	
	Return StrTemplate(NStr("vi = 'Bước 1/%1: Đăng nhập dịch vụ đám mây';
							|ru = 'Шаг 1 из %1: Вход в облачный сервис';
							|en = 'Step 1 out of %1: Logging in to the cloud service'; fa = 'Step 1 out of %1: Logging in to the cloud service';
							|it = 'Passaggio 1 di %1: Accesso al cloud';
							|pl = 'Krok 1 z %1: Wejście do serwisu w chmurze';
							|tr = '%1 adımından 1. adım: Bulut servisine giriş'"), TotalWizardSteps());

EndFunction

&AtClient
Function HeaderMatchingUsers()
	
	Return StrTemplate(NStr("vi = 'Bước %1 trong số %2: So sánh người sử dụng';
							|ru = 'Шаг %1 из %2: Сопоставление пользователей';
							|en = 'Step %1 out of %2: Mapping users'; fa = 'Step %1 out of %2: Mapping users';
							|it = 'Step %1 out of %2: Mapping users';
							|pl = 'Step %1 out of %2: Mapping users';
							|tr = '%1/%2. adım: Kullanıcı eşleştirmesi'"), ?(RecoveryExtensions.Count() = 0, 3, 4), TotalWizardSteps());

EndFunction

&AtClient
Function TitleExtensionsMatching()
	
	
	Return StrTemplate(NStr("vi = 'Bước 3 trong số %1: So sánh phần mở rộng';
							|ru = 'Шаг 3 из %1: Сопоставление расширений';
							|en = 'Step 3 out of %1: Mapping extensions'; fa = 'Step 3 out of %1: Mapping extensions';
							|it = 'Шаг 3 из %1: Сопоставление расширений';
							|pl = 'Step 3 out of %1: Mapping extensions';
							|tr = '%1 adımından 3. adım: Uzantıların eşleştirilmesi'"), TotalWizardSteps());

EndFunction

&AtClient
Function TotalWizardSteps()
	TotalSteps = 3;
	If IBUsers.Count() > 0 Then
		TotalSteps = TotalSteps + 1;
	EndIf;
	If RecoveryExtensions.Count() > 0 Then
		TotalSteps = TotalSteps + 1;
	EndIf;
	Return TotalSteps;
EndFunction
	
&AtClient
Function HeaderUploadingData()
	
	Return ?(TheFileIsBeingSaved, 
		NStr("vi = 'Kết xuất dữ liệu';
			|ru = 'Выгрузка данных';
			|en = 'Exporting data'; fa = 'خروج داده';
			|it = 'Caricamento dei dati';
			|pl = 'Przesyłanie danych';
			|tr = 'Veri dışa aktarma'"), 
			StrTemplate(NStr("vi = 'Bước %1/%1. Kết xuất dữ liệu';
							|ru = 'Шаг %1 из %1: Выгрузка данных';
							|en = 'Step %1 out of %1. Exporting data.'; fa = 'Step %1 out of %1. Exporting data.';
							|it = 'Passaggio %1 di %1: Upload dati';
							|pl = 'Krok %1 z %1. Eksport danych';
							|tr = '%1 adımından %1 adım: Verilerin dışa aktarılması'"), ?(IBUsers.Count() = 0, 4, TotalWizardSteps())));

EndFunction

#EndRegion 

#Region FillingInCloudServiceSettings

&AtClient
Procedure CheckServiceAddress()
	
	If ValueIsFilled(ServiceAddress) Then
		Items.Next.Enabled = False;
		ShowWaitingState(Items.CheckingTheServiceAddress.Name);
		QueryOptions = TemplateForQueryParameters();
		QueryOptions.Insert("Name", ConfigurationName);
		QueryOptions.Insert("Version", ConfigurationVersion);
		StartRequestBySettings(QueryOptions, HandlerResults_1, StorageAddress, JobID);
		CheckQueryResult();
	EndIf;

EndProcedure

&AtServerNoContext
Procedure StartRequestBySettings(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	HandlerResults_1 = "Attachable_FillSettings";
	MethodName = "GetInformationAboutTransitionOptions";
	QueryOptions.Insert("MethodInformation", "info");
	QueryOptions.Insert("LoadingOptionsMethod", 
		StrTemplate("import-options?name=%1&version=%2", QueryOptions.Name, QueryOptions.Version));
    StartBackgroundJobOnServer(MethodName, QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_FillSettings(Result, AdditionalParameters) Export
	
	// If a different transition method was selected in the process of receiving data, 
	// you need to refuse to fill in.
	If Not TransitionMethod = UploadMethod() Or TypeOf(Result) <> Type("Structure") Or Not Result.Property(
		"Information") Then
		Return;
	EndIf;
	
	Debugging_ConfigurationNotSupported = (LaunchParameter = "DebuggingTransitionToCloud/ConfigurationIsNotSupported");
	Debugging_NoServiceOrganizationsAvailable = (LaunchParameter = "DebuggingTransitionToCloud/ThereAreNoServiceOrganizations");
	Debugging_MigrationNotAvailable = (LaunchParameter = "DebuggingTransitionToCloud/MigrationIsNotAvailable");
	Debugging_MigrationIsAvailable = (LaunchParameter = "DebuggingTransitionToCloud/MigrationIsAvailable");
	Debugging_UnloadingIsNotAvailable = (LaunchParameter = "DebuggingTransitionToCloud/UploadIsNotAvailable");
	Debugging_NoRegistrationPromptAvailable = (LaunchParameter = "DebuggingTransitionToCloud/NoRegistrationInvitationIsAvailable");
	
	NameOfStateElement = Items.CheckingTheServiceAddress.Name;
	If Result.Information.StatusCode <> 200 Then
		ShowErrorState(NameOfStateElement);
		
		If DataSeparationEnabled Then
			MessageTemplate = NStr("vi = 'Không tìm thấy dịch vụ đám mây hoặc không hỗ trợ chuyển trực tiếp sang dịch vụ.';
									|ru = 'Облачный сервис не найден или не поддерживает интерактивный перенос в сервис.';
									|en = 'Cloud service is not found or it does not support interactive transfer to the service.'; fa = 'Cloud service is not found or it does not support interactive transfer to the service.';
									|it = 'Servizio cloud non trovato o non supporta il trasferimento interattivo nel servizio.';
									|pl = 'Serwis w chmurze nie jest znaleziony lub nie obsługuje interaktywnego przeniesienia do serwisu.';
									|tr = 'Bulut hizmeti bulunamadı veya servise interaktif aktarımı desteklemiyor.'");			
		Else
			MessageTemplate = NStr("vi = 'Không tìm thấy dịch vụ đám mây hoặc không hỗ trợ chuyển trực tác sang dịch vụ.';
									|ru = 'Облачный сервис не найден или не поддерживает интерактивный переход в сервис.';
									|en = 'Cloud service is not found or it does not support interactive migration to the service.'; fa = 'Cloud service is not found or it does not support interactive migration to the service.';
									|it = 'Servizio cloud non trovato o non supporta il passaggio interattivo nel servizio.';
									|pl = 'Serwis w chmurze nie jest znaleziony lub nie obsługuje interaktywnego przejścia do serwisu.';
									|tr = 'Bulut hizmeti bulunamadı veya servise interaktif taşımayı desteklemiyor.'");			
		EndIf; 
		
		CommonClient.MessageToUser(MessageTemplate, ,
			Items.ServiceAddress.Name, Items.ServiceAddress.Name);
		Return;
	EndIf;
	
	Data = Result.Information.Data;
	
	If Not Data.Enabled Then
		ShowErrorState(NameOfStateElement);
		
		If DataSeparationEnabled Then
			MessageTemplate =  NStr("vi = 'Dịch vụ đám mây không hỗ trợ chuyển trực tác sang dịch vụ.';
									|ru = 'Облачный сервис не поддерживает интерактивный перенос в сервис.';
									|en = 'Cloud service does not support interactive transfer to the service.'; fa = 'Cloud service does not support interactive transfer to the service.';
									|it = 'Servizio cloud non supporta il trasferimento interattivo nel servizio.';
									|pl = 'Serwis w chmurze nie obsługuje interaktywnego przeniesienia do serwisu.';
									|tr = 'Bulut hizmeti servise interaktif aktarımı desteklemiyor.'");
		Else
			MessageTemplate =  NStr("vi = 'Dịch vụ đám mây không hỗ trợ chuyển trực tác sang dịch vụ.';
									|ru = 'Облачный сервис не поддерживает интерактивный переход в сервис.';
									|en = 'Cloud service does not support interactive migration to the service.'; fa = 'Cloud service does not support interactive migration to the service.';
									|it = 'Servizio cloud non supporta il passaggio interattivo nel servizio.';
									|pl = 'Serwis w chmurze nie obsługuje interaktywnego przejścia do serwisu.';
									|tr = 'Bulut hizmeti servise interaktif taşımayı desteklemiyor.'");
		EndIf;
		
		CommonClient.MessageToUser(MessageTemplate, ,
			Items.ServiceAddress.Name, Items.ServiceAddress.Name);
		Return;
	EndIf; 
	
	RegistrationAddress = Data.url_register;
	RecoveryAddress = Data.url_recover;
	APIAddress = Data.url_api;
	Data.Property("api_version", SoftwareInterfaceVersion);
	
	RestoringRegistration = New Array;
	RestoringRegistration.Add(New FormattedString(NStr("vi = 'Quên tên đăng nhập hoặc mật khẩu?';
														|ru = 'Забыли логин или пароль?';
														|en = 'Forgot your username or password?'; fa = 'Forgot your username or password?';
														|it = 'Password o login dimenticati?';
														|pl = 'Nie pamiętasz loginu lub hasła?';
														|tr = 'Kullanıcı adı veya parolayı unuttunuz mu?'")));
	RestoringRegistration.Add(New FormattedString(" "));
	RestoringRegistration.Add(New FormattedString(NStr("vi = 'Khôi phục';
														|ru = 'Восстановить';
														|en = 'Reset'; fa = 'بازنشانی';
														|it = 'Ripristinare';
														|pl = 'Reset';
														|tr = 'Geri yükle'"),,,, Data.url_recover));
	RestoringRegistration.Add(New FormattedString(Chars.LF + Chars.LF));
	RestoringRegistration.Add(New FormattedString(NStr("vi = 'Không đăng ký trên đám mây?';
														|ru = 'Не зарегистрированы в облаке?';
														|en = 'Don''t have an account yet?'; fa = 'Don''t have an account yet?';
														|it = 'Non hai una registrazione nel cloud?';
														|pl = 'Nie jesteś zarejestrowany/na w chmurze?';
														|tr = 'Bulutta kaydınız yok mu?'")));
	RestoringRegistration.Add(New FormattedString(" "));
	RestoringRegistration.Add(New FormattedString(NStr("vi = 'Đăng ký';
														|ru = 'Зарегистрироваться';
														|en = 'Sign up'; fa = 'Sign up';
														|it = 'Registrarsi';
														|pl = 'Sign up';
														|tr = 'Kayıt ol'"),,,,  RefRegistration()));
	Items.RestoringRegistration.Title = New FormattedString(RestoringRegistration);
	
	Data.Property("register_available", RegistrationRequestAvailable);
	If Not Debugging_NoRegistrationPromptAvailable Then
		Data.Property("invitation_available", AnInvitationToRegisterIsAvailable);
	EndIf;
	Data.Property("support_companies_available", UseOfServiceProviders);
	Data.Property("url_adm", PersonalAccountAddress);
	Data.Property("url_epf", AddressOfProcessingOnTheServer);
	
	If UseOfServiceProviders And Not Debugging_NoServiceOrganizationsAvailable Then
		Data.Property("support_companies_count", NumberOfServiceOrganizations);
	EndIf;
	
	ProviderContactsField = "provider_contacts";
	If Data.Property(ProviderContactsField) Then
		ProviderContacts = Data[ProviderContactsField];
		ProviderCity = ProviderContacts.city;
		WebsiteProvider = ProviderContacts.site;
		ProviderPhoneNumber = ProviderContacts.phone;
		MailProvider = ProviderContacts.email;
	EndIf; 
	
	If Data.applications.Find(ConfigurationName) = Undefined Or Debugging_ConfigurationNotSupported Then
		ShowErrorState(NameOfStateElement);
		CommonClient.MessageToUser(
			StrTemplate(NStr("vi = 'Dịch vụ đám mây không hỗ trợ cấu hình ''%1''';
							|ru = 'Облачный сервис не поддерживает конфигурацию ''%1''';
							|en = 'Cloud service does not support the ''%1'' configuration'; fa = 'Cloud service does not support the ''%1'' configuration';
							|it = 'Il servizio cloud non supporta la configurazione ''%1''';
							|pl = 'Serwis w chmurze nie obsługuje konfiguracji ''%1''';
							|tr = 'Bulut hizmeti ''%1'' konfigürasyonu desteklemiyor'"), ConfigurationSynonym),, 
			Items.ServiceAddress.Name, Items.ServiceAddress.Name);
		Items.Next.Enabled = False;
		Return;
	EndIf;
	
	Error = False;
	ErrorMessage = "";
	Data = Result.ImportOptions.Data;
	If Result.ImportOptions.Error Then
		Error = True;
		ErrorMessage = Result.ImportOptions.ErrorMessage;
	ElsIf Data.error Then 
		Error = True;
		ErrorMessage = Data.description;
	EndIf;
	
	If Error Then
		CommonClient.MessageToUser(ErrorMessage,, Items.ServiceAddress.Name);
		ShowErrorState(NameOfStateElement);
	Else
		If Debugging_MigrationIsAvailable Then
			MigrationIsAvailable = True;
		ElsIf Debugging_MigrationNotAvailable Then
			MigrationIsAvailable = False;
		Else
			MigrationIsAvailable = Data.migration;
		EndIf; 
		If Not Debugging_UnloadingIsNotAvailable Then
			UploadIsAvailable = Data.upload;
		EndIf;
		TheMinimumVersionRequiredToDischarge = Data.upload_min_version;
		For Each SupportedVersion In Data.migration_versions Do
			If SupportedVersionsForMigration.FindByValue(SupportedVersion) = Undefined Then
				SupportedVersionsForMigration.Add(SupportedVersion);
			EndIf;
		EndDo;
		SetVisibilityByUpdateState();
		ShowStateReady(NameOfStateElement);
		Items.Next.Enabled = True;
	EndIf; 
	
EndProcedure

#EndRegion

#Region EmailAddressVerification

&AtClient
Procedure CheckEmailAddress()
	
	If ValueIsFilled(RegistrationMail) And CheckInOption <> OptionEnterActivationCode() Then
		ShowWaitingState(Items.CheckingYourEmail.Name);
		QueryOptions = TemplateForQueryParameters();
		QueryOptions.Insert("Mail", RegistrationMail);
		StartCheckingMail(QueryOptions, HandlerResults_1, StorageAddress, JobID);
		CheckQueryResult();
	Else
		ShowStateEmpty("CheckingYourEmail");
	EndIf;

EndProcedure

&AtServerNoContext
Procedure StartCheckingMail(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	HandlerResults_1 = "Attachable_ShowResultOfCheckingEmailAddress"; 
	QueryOptions.Insert("Method", StrTemplate("email-available?email=%1", 
		EncodeString(QueryOptions.Mail, StringEncodingMethod.URLEncoding)));
	
	StartBackgroundJobOnServer("GetData", QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_ShowResultOfCheckingEmailAddress(Result, AdditionalParameters) Export
	
	Error = False;
	ErrorMessage = "";
	NameOfStateElement = Items.CheckingYourEmail.Name;
	Data = Result.Data;
	If Result.Error Then
		Error = True;
		ErrorMessage = Result.ErrorMessage;
	ElsIf Data.error Then 
		Error = True;
		ErrorMessage = Data.description;
	EndIf;
	
	If Error Then
		If CheckInOption <> OptionRequestForRegistration() And  Result.StatusCode = 409 Then
			ErrorMessage = ErrorMessage + Chars.LF + StrTemplate(
				NStr("vi = 'Đã đăng ký trước? Quay lại một bước và chọn phương án ''%1''.';
					|ru = 'Регистрировались ранее? Вернитесь на шаг назад и выберите вариант ''%1''.';
					|en = 'Already registered? Please step back and select the ''%1'' option.'; fa = 'Already registered? Please step back and select the ''%1'' option.';
					|it = 'Hai già un account? Torna al passaggio precedente e seleziona opzione ''%1''.';
					|pl = 'Rejestrowałeś/aś się wcześniej? Wróć o krok z powrotem i wybierz wariant ''%1''.';
					|tr = 'Daha önceden kaydınız var mı? Bir adım geri dönün ve ''%1'' seçeneği seçin.'"),
				Items.EnterTheActivationCode.ChoiceList[0].Presentation);
		EndIf; 
		CommonClient.MessageToUser(ErrorMessage, , Items.RegistrationMail.Name);
		ShowErrorState(NameOfStateElement);
	Else	
		ShowStateReady(NameOfStateElement);
	EndIf; 
	
EndProcedure
 
#EndRegion 

#Region FillingInActivationData

&AtClient
Procedure CheckActivationCode()
	
	NameOfStateElement = Items.CheckingOfActivationCode.Name;
	If ValueIsFilled(ActivationCode) Then
		ShowWaitingState(NameOfStateElement);
		QueryOptions = TemplateForQueryParameters();
		QueryOptions.Insert("ActivationCode", ActivationCode);
		StartRequestByActivationCode(QueryOptions, HandlerResults_1, StorageAddress, JobID);
		CheckQueryResult();
	Else
		ShowStateEmpty(NameOfStateElement);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Procedure StartRequestByActivationCode(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	HandlerResults_1 = "Attachable_FillInActivationCodeDetails";
	QueryOptions.Insert("Method", StrTemplate("reg-info?code=%1", 
		EncodeString(QueryOptions.ActivationCode, StringEncodingMethod.URLEncoding)));
    StartBackgroundJobOnServer("GetData", QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_FillInActivationCodeDetails(Result, AdditionalParameters) Export
	
	Data = Result.Data;
	NameOfStateElement = Items.CheckingOfActivationCode.Name;
	
	If Result.Error Then
		ShowErrorState(NameOfStateElement);
		CommonClient.MessageToUser(Result.ErrorMessage,, 
			Items.ActivationCode.Name);
	 
	ElsIf Data.Error Then
		ShowErrorState(NameOfStateElement);
		CommonClient.MessageToUser(Data.description,, 
			Items.ActivationCode.Name);
	Else
		ShowStateReady(NameOfStateElement);
		Information = Data.info;
		
		If Data.type = TypeOfRegistrationInvitation() Then
			PublicOrganizationInformation = Data.supportCompany;
			SPCode = PublicOrganizationInformation.id;
			SPCity = PublicOrganizationInformation.city;
			SPDescription = PublicOrganizationInformation.name;
			SPSite = PublicOrganizationInformation.site;
			SPPhone = PublicOrganizationInformation.phone;
			SPMail = PublicOrganizationInformation.email;
		Else
			CheckInOption = OptionRequestForRegistration();
			SetPageEnterActivationCode(Items.Pages.CurrentPage);
			StartActivatingRegistrationCode();
		EndIf;
		
		RegistrationName = Information.name;
		RegistrationLogin = ?(Information.Property("login"), Information.login, Information.email);
		RegistrationMail = Information.email;
		RegistrationPhone = Information.phone;
		
		ShowFillInFlag(RegistrationName, Items.CheckingTheName.Name);
		ShowStateReady(Items.CheckingYourEmail.Name);
		ShowFillInFlag(RegistrationPhone, Items.CheckingYourPhone.Name);
		
	EndIf; 
	
EndProcedure
 
#EndRegion 

#Region RegistrationInService

&AtClient
Procedure StartRegisteringInService(CurrentPage)
	
	RegistrationLogin = RegistrationMail; // For registrations in the Transition Wizard, mail is assigned as a login.
	
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Name", RegistrationName);
	QueryOptions.Insert("Mail", RegistrationMail);
	QueryOptions.Insert("Login", RegistrationLogin);
	QueryOptions.Insert("Phone", RegistrationPhone);
	QueryOptions.Insert("Password", RegistrationPassword);
	QueryOptions.Insert("ActivationCode", ActivationCode);
	QueryOptions.Insert("SPCode", SPCode);
	QueryOptions.Insert("CheckInOption", CheckInOption);
	If AnInvitationToRegisterIsAvailable Then
		TypeOfRegistration = TypeOfRegistrationInvitation();
	ElsIf ValueIsFilled(ActivationCode) Then
		TypeOfRegistration = TypeOfRegistrationRequest();
	Else
		TypeOfRegistration = TypeOfRegistrationManual();
	EndIf; 
	
	QueryOptions.Insert("TypeOfRegistration", TypeOfRegistration);

	StartRegistrationRequest(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	If CheckInOption = OptionOoSelection() Or CheckInOption = OptionEnterActivationCode() Then
		DescriptionOfWaiting = ServiceOrganizationContactLine();
	ElsIf CheckInOption = OptionRequestForRegistration() Then
		DescriptionOfWaiting = SupportContactLine();
	Else
		DescriptionOfWaiting = ?(NumberOfServiceOrganizations = 0, 
			SupportContactLine(), OrganizationAutoSelectionLine());
	EndIf;
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = NStr("vi = 'Đăng ký dịch vụ đám mây';
									|ru = 'Регистрация в облачном сервисе';
									|en = 'Registration in cloud service'; fa = 'Registration in cloud service';
									|it = 'Registrazione nel cloud';
									|pl = 'Rejestracja w serwisie w chmurze';
									|tr = 'Bulut servisinde kayıt'");
	IdleParameters.StateDescription = NStr("vi = 'Đang đăng ký...';
											|ru = 'Выполняется регистрация...';
											|en = 'Registering…'; fa = 'Registering…';
											|it = 'Registrazione in corso...';
											|pl = 'Trwa rejestracja...';
											|tr = 'Kayıt yapılıyor...'");
	IdleParameters.DescriptionOfWaiting = DescriptionOfWaiting;
	IdleParameters.DisplayDescriptionTitle = True;
	IdleParameters.AcceptableWaitingTime = 5;
	SetWaitingPage(CurrentPage, IdleParameters);

EndProcedure

&AtServerNoContext
Procedure StartRegistrationRequest(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	Data = New Structure;
	Data.Insert("type", QueryOptions.TypeOfRegistration);
	Data.Insert("login", QueryOptions.Login);
	Data.Insert("name", QueryOptions.Name);
	Data.Insert("password", QueryOptions.Password);
	Data.Insert("email",QueryOptions.Mail);
	Data.Insert("phone", QueryOptions.Phone);
	If QueryOptions.CheckInOption = OptionEnterActivationCode() Then
		Data.Insert("code", QueryOptions.ActivationCode);
	EndIf; 
	If QueryOptions.CheckInOption = OptionOoSelection() Then
		Data.Insert("supportCompanyId", QueryOptions.SPCode);
	EndIf;
	
	HandlerResults_1 = "Attachable_FillOutFormAfterRegistration"; 
	QueryOptions.Insert("Data", Data);
	QueryOptions.Insert("Method", "register");
	StartBackgroundJobOnServer("SendData", QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_FillOutFormAfterRegistration(Result, AdditionalParameters) Export
	
	If Result.Error Then
		ShowErrorOnWaitingPage(Result.ErrorMessage);
		Return;
	EndIf; 
	
	Data = Result.Data;
	If Data.error Then
		ShowErrorOnWaitingPage(Data.description);
	Else
		ShowWaitingState("StatePicture");
		Login = RegistrationLogin;
		Password = RegistrationPassword;
		If CheckInOption = OptionRequestForRegistration() Then
			SetPageEnterActivationCode(Items.Pages.CurrentPage);
		Else
			StartLoggingInToService(Items.Pages.CurrentPage);
		EndIf; 
	EndIf; 
		
EndProcedure

&AtClient
Procedure CheckPasswordEntry()
	
	If ValueIsFilled(RegistrationPassword) And ValueIsFilled(RegistrationPasswordConfirmation)
		And RegistrationPassword = RegistrationPasswordConfirmation Then
		ShowStateReady(Items.PasswordCheck.Name);
	Else
		ShowStateEmpty(Items.PasswordCheck.Name)
	EndIf;

EndProcedure

#EndRegion

#Region ActivatingRegistrationCode

&AtClient
Procedure StartActivatingRegistrationCode()
	
	If ValueIsFilled(ActivationCode) Then
		ShowWaitingState(Items.CheckingActivationCode.Name);
		QueryOptions = TemplateForQueryParameters();
		QueryOptions.Insert("ActivationCode", ActivationCode);
		StartActivationRequest(QueryOptions, HandlerResults_1, StorageAddress, JobID);
		CheckQueryResult();
	Else
		ShowStateEmpty(Items.CheckingActivationCode.Name);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Procedure StartActivationRequest(QueryOptions, HandlerResults_1, StorageAddress, JobID) 
	
	Data = New Structure;
	Data.Insert("code", QueryOptions.ActivationCode);
	
	HandlerResults_1 = "Attachable_FillOutFormAfterActivation"; 
	QueryOptions.Insert("Method", "activation");
	QueryOptions.Insert("Data", Data);
	StartBackgroundJobOnServer("SendData", QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_FillOutFormAfterActivation (Result, AdditionalParameters) Export

	Error = False;
	ErrorMessage = "";
	NameOfStateElement = Items.CheckingActivationCode.Name;
	Data = Result.Data;
	If Result.Error Then
		Error = True;
		ErrorMessage = Result.ErrorMessage;
	ElsIf Data.error Then 
		Error = True;
		ErrorMessage = Data.description;
	EndIf;
	
	If Error Then
		CommonClient.MessageToUser(ErrorMessage,, Items.ActivationCodeRegistrationRequest.Name);
		ShowErrorState(NameOfStateElement);
	Else
		LoginField = "login";
		If Data.Property(LoginField) Then
			RegistrationLogin = Data[LoginField];
		Else
			RegistrationLogin = RegistrationMail;
		EndIf;
		Login = RegistrationLogin;
		Password = RegistrationPassword;
		ShowStateReady(Items.CheckingActivationCode.Name);
		If ValueIsFilled(Password) Then
			StartLoggingInToService(Items.Pages.CurrentPage);
		EndIf; 
	EndIf; 
	
EndProcedure
 
#EndRegion

#Region LogInToService

&AtClient
Procedure StartLoggingInToService(CurrentPage)
	
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Login", Login);
	QueryOptions.Insert("Password", Password);
	QueryOptions.Insert("Method", "usr/account/list");
	QueryOptions.Insert("HandlerResults_1", "Attachable_FillOutFormAfterLoggingIn");
	
	StartExecutingInterfaceMethod(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = EntryHeader();
	IdleParameters.StateDescription = NStr("vi = 'Đang đăng nhập...';
											|ru = 'Выполняется вход...';
											|en = 'Logging in…'; fa = 'Logging in…';
											|it = 'Accesso in corso...';
											|pl = 'Trwa wejście...';
											|tr = 'Giriş yapılıyor...'");
	IdleParameters.AcceptableWaitingTime = 5;
	SetWaitingPage(CurrentPage, IdleParameters);

EndProcedure

&AtClient
Procedure Attachable_FillOutFormAfterLoggingIn(Result, AdditionalParameters) Export
	
	If Result.Error Then
		ShowErrorOnWaitingPage(Result.ErrorMessage);
		Return;
	EndIf;
	
	SetDefaultControls();
	
	ChoiceList = Items.SubscriberCode_2.ChoiceList;
	Data = Result.Data;
	ChoiceList.Clear();
	For Each Item In Data.account Do
		If Item.role = OwnerRole() Then
			If Not ValueIsFilled(SubscriberCode) Then
				SubscriberCode = Item.id;
				SubscriberName_3 = Item.name;
			EndIf;
			ChoiceList.Add(Item.id, Item.name);
		EndIf; 
	EndDo;
	
	SetTransitionMethodPage(Items.Pages.CurrentPage); 
	
EndProcedure
 
#EndRegion

#Region ExtensionsMatching

&AtClient
Function CheckExtensionsForRecoveryCompletion()
	Cancel = False;
	
	ExtensionsToLineNumbersMatching = New Map;
	
	LineNumber = 0;
	For Each StringExtension In RecoveryExtensions Do
		LineNumber = LineNumber + 1;
		If StringExtension.Refresh And Not ValueIsFilled(StringExtension.UseExtension) Then
			MessageText = StrTemplate(
				NStr("vi = 'Đối với phần mở rộng ''%1'' đã chỉ ra việc cần khôi phục, nhưng chưa chọn phần mở rộng được khôi phục của dịch vụ';
					|ru = 'Для расширения ''%1'' указана необходимость восстановления, но не выбрано восстанавливаемое расширение сервиса';
					|en = 'The %1 extension requires recovery but the service extension to restore is not selected'; fa = 'The %1 extension requires recovery but the service extension to restore is not selected';
					|it = 'Для расширения ''%1'' указана необходимость восстановления, но не выбрано восстанавливаемое расширение сервиса';
					|pl = 'The %1 extension requires recovery but the service extension to restore is not selected';
					|tr = 'Uzantı ''%1'' geri yüklenecek gerekliliği belirtilmiş, ancak geri yüklenecek hizmet uzantısı seçilmedi'"), 
				StringExtension.Description);
			
			DataPath = CommonClientServer.PathToTabularSection("RecoveryExtensions",
				LineNumber, 
				"UseExtension");
			
			CommonClient.MessageToUser(MessageText,, DataPath,, Cancel);
			Continue;
		EndIf;
		
		If Not ValueIsFilled(StringExtension.UseExtension) Then
			Continue;
		EndIf;
		
		LineNumbers = ExtensionsToLineNumbersMatching.Get(StringExtension.UseExtension);
		If LineNumbers = Undefined Then
			LineNumbers = New Array;
			ExtensionsToLineNumbersMatching.Insert(StringExtension.UseExtension, LineNumbers);
		EndIf;
		LineNumbers.Add(LineNumber);
	EndDo;
	
	For Each KeyValue In ExtensionsToLineNumbersMatching Do		
		LineNumbers = KeyValue.Value;
		If LineNumbers.Count() = 1 Then
			Continue;
		EndIf;
		
		MessageText = StrTemplate(NStr("vi = 'Đã tìm thấy sự trùng lặp của phần mở rộng ''%1'' trong các dòng số %2';
										|ru = 'Обнаружено дублирование расширения ''%1'' в строках № %2';
										|en = 'The %1 extension duplicate is detected in lines %2'; fa = 'The %1 extension duplicate is detected in lines %2';
										|it = 'Обнаружено дублирование расширения ''%1'' в строках № %2';
										|pl = 'The %1 extension duplicate is detected in lines %2';
										|tr = 'Tekrarlanan ''%1'' uzantısı №%2 satırında bulundu'"), 
			KeyValue.Key, 
			StrConcat(LineNumbers, ", "));
		DataPath = CommonClientServer.PathToTabularSection("RecoveryExtensions",
			LineNumbers[0], 
			"UseExtension");
		CommonClient.MessageToUser(MessageText,, DataPath,, Cancel);
	EndDo;
	
	Return Not Cancel;
EndFunction

&AtClient
Procedure ProcessExtensionSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	ProcessExtensionSelectionAtServer(Result, Items.RecoveryExtensions.CurrentRow);
	
EndProcedure

&AtServer
Procedure ProcessExtensionSelectionAtServer(ExtensionName, CurrentRow)
	RowsArray = ExtensionsFromSM.FindRows(New Structure("Name", ExtensionName));
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	ExtensionRow = RowsArray[0];
	CurRow = RecoveryExtensions[CurrentRow];
	
	If CurRow.ModifiesDataStructure <> ExtensionRow.ModifiesDataStructure Then
		If ExtensionRow.ModifiesDataStructure Then
			Text = NStr("vi = 'Chú ý: Phần mở rộng ""%1"" không thay đổi cấu trúc dữ liệu,
				|nhưng đã chọn phần mở rộng thay đổi cấu trúc dữ liệu.';
				|ru = 'Обратите внимание: Расширение ""%1"" не изменяет структуру данных,
				|но выбрано расширение изменяющее структуру данных.';
				|en = 'Note: The %1 extension does not change the data structure,
				|but an extension that changes the data structure is selected.'; fa = 'Note: The %1 extension does not change the data structure,
				|but an extension that changes the data structure is selected.';
				|it = 'Note: The %1 extension does not change the data structure,
				|but an extension that changes the data structure is selected.';
				|pl = 'Note: The %1 extension does not change the data structure,
				|but an extension that changes the data structure is selected.';
				|tr = 'Dikkat edin: ""%1"" eklentisi, veri yapısını değiştirmez,
				|fakat veri yapısını değiştiren bir eklenti seçilir.'");
		EndIf;
		MessageText = StrTemplate(Text, CurRow.Description);
		DataPath = CommonClientServer.PathToTabularSection("RecoveryExtensions",
			CurrentRow + 1, "UseExtension");
		Common.MessageToUser(MessageText,, DataPath);
	EndIf;
	
	CurRow.UseExtensionName = ExtensionName;
	CurRow.Version = ExtensionRow.Version;
	CurRow.UseExtension = ExtensionRow.Description;
	If Not CurRow.Refresh Then
		CurRow.Refresh = True;
	EndIf;
EndProcedure

&AtClient
Procedure StartExtensionsMatching(CurrentPage)
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Login", Login);
	QueryOptions.Insert("Password", Password);
	QueryOptions.Insert("SubscriberCode", SubscriberCode);
	QueryOptions.Insert("Method", "usr/extension/list_for_compare");
	QueryOptions.Insert("HandlerResults_1", "Attachable_FillInExtensionsList");
	
	Data = New Structure;
	Data.Insert("account", SubscriberCode);
	Data.Insert("sysname", "");
	Data.Insert("sysversion", "");
	
	QueryOptions.Insert("Data", Data);
	
	StartExecutingInterfaceMethod(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = TitleExtensionsMatching();
	IdleParameters.StateDescription = NStr("vi = 'Đọc danh sách phần mở rộng...';
											|ru = 'Чтение списка расширений...';
											|en = 'Reading the extension list...'; fa = 'Reading the extension list...';
											|it = 'Чтение списка расширений...';
											|pl = 'Reading the extension list...';
											|tr = 'Uzantı listesini okuma...'");
	IdleParameters.AcceptableWaitingTime = 5;

	SetWaitingPage(CurrentPage, IdleParameters);
EndProcedure

&AtClient
Procedure Attachable_FillInExtensionsList(Result, AdditionalParameters) Export	
	If HasErrors(Result) Then
		Return;
	EndIf;
	SetDefaultControls();
	
	FillInExtensionsListAtServer(Result.Data);
	
	SetExtensionsMappingPage(Items.Pages.CurrentPage);
EndProcedure

&AtServer
Procedure FillInExtensionsListAtServer(Data)	
	ExtensionsFromSM.Clear();
	Items.RecoveryExtensionsVersion.ChoiceList.Clear();
	For Each Item In Data.extension Do
		NewRow = ExtensionsFromSM.Add();
		NewRow.Description = Item.description;
		NewRow.Version = Item.version;
		NewRow.Name = Item.id;
		NewRow.ModifiesDataStructure = Item.changes_data_structure;
	EndDo;
	ExtensionsStorageURL = PutToTempStorage(ExtensionsFromSM.Unload(), UUID);
EndProcedure

&AtServer
Procedure FillInIBExtensions()
	SetPrivilegedMode(True);
	SelectExtensionsFromArea = Common.SeparatedDataUsageAvailable()
		And Common.DataSeparationEnabled();

	PlusExtensions = New Map();
	ExportImportDataInternal.FillInInstalledPlusExtensions(PlusExtensions);
	
	For Each ConfigurationExtension In ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied) Do
		If Not ConfigurationExtension.Active 
			Or PlusExtensions.Get(ConfigurationExtension.UUID) <> Undefined Then
			Continue;
		EndIf;
		If SelectExtensionsFromArea And 
			ConfigurationExtension.Scope = ConfigurationExtensionScope.InfoBase Then
			Continue;
		EndIf;
		StringExtension = RecoveryExtensions.Add();
		StringExtension.Description = 
			?(ValueIsFilled(ConfigurationExtension.Synonym), ConfigurationExtension.Synonym, ConfigurationExtension.Name);
		StringExtension.ModifiesDataStructure = ConfigurationExtension.ModifiesDataStructure();
		StringExtension.Refresh = StringExtension.ModifiesDataStructure;
	EndDo;
EndProcedure

#EndRegion

#Region UserMatching

&AtClient
Procedure StartMatchingUsers(CurrentPage)
	
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Login", Login);
	QueryOptions.Insert("Password", Password);
	QueryOptions.Insert("SubscriberCode", SubscriberCode);
	QueryOptions.Insert("Method", "usr/account/users/list");
	QueryOptions.Insert("HandlerResults_1", "Attachable_FillUserList");
	
	Data = New Structure;
	Data.Insert("id", SubscriberCode);
	
	QueryOptions.Insert("Data", Data);
	
	StartExecutingInterfaceMethod(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = HeaderMatchingUsers();
	IdleParameters.StateDescription = NStr("vi = 'Đọc danh sách người sử dụng...';
											|ru = 'Чтение списка пользователей...';
											|en = 'Reading the user list…'; fa = 'Reading the user list…';
											|it = 'Lettura dell''elenco utenti...';
											|pl = 'Odczytywanie listy użytkowników...';
											|tr = 'Kullanıcı listesini okuma...'");
	IdleParameters.AcceptableWaitingTime = 5;

	SetWaitingPage(CurrentPage, IdleParameters);

EndProcedure

&AtClient
Procedure Attachable_FillUserList(Result, AdditionalParameters) Export
	
	If HasErrors(Result) Then
		Return;
	EndIf; 
	Data = Result.Data;
	SetDefaultControls();
	
	UsersRights.Clear();
	For Each Item In Data.user Do
		NewRow = UsersRights.Add();
		NewRow.FullName = Item.name;
		NewRow.Login = Item.login;
		NewRow.ThisIsTheSubscriberOwner = (Item.role = OwnerRole());
	EndDo;
	UsersRights.Sort("FullName");
	
	MatchUsers();
	UpdateUserMappingStatus();
	SetUserMappingPage(Items.Pages.CurrentPage); 
	
EndProcedure

&AtClient
Procedure CreateServiceUser()
	
	FormParameters = New Structure;
	FormParameters.Insert("Login", Login);
	FormParameters.Insert("Password", Password);
	FormParameters.Insert("SubscriberCode", SubscriberCode);
	FormParameters.Insert("APIAddress", APIAddress);
	FormParameters.Insert("SoftwareInterfaceVersion", SoftwareInterfaceVersion);
	
	CurrentData = Items.UsersRights.CurrentData;
	If CurrentData <> Undefined And Not ValueIsFilled(CurrentData.FullName) Then
		FormParameters.Insert("FullName", CurrentData.FullNameOfTheIBUser);
		FormParameters.Insert("Id", CurrentData.Id);
		FormParameters.Insert("Mail", CurrentData.Email);
	Else
		FormParameters.Insert("FullName", "");
		FormParameters.Insert("Id", Undefined);
		FormParameters.Insert("Mail", "");
	EndIf; 
	
	Notification = New CallbackDescription("CreateServiceUserCompletion", ThisObject);
	
	ChoiceFormName = "DataProcessor.WizardOfTransitionToCloud.Form.AddUser";
	
	OpenForm(ChoiceFormName, FormParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure CreateServiceUserCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		NewRow = UsersRights.Add();
		NewRow.FullName = Result.FullName;
		NewRow.Login = Result.Login;
		NewRow.ThisIsTheSubscriberOwner = (Result.Role = OwnerRole());
		If ValueIsFilled(Result.Id) Then
			Search = IBUsers.FindRows(New Structure("Id", Result.Id));
			If Search.Count() > 0 Then
				Search[0].ServiceUserLogin = Result.Login;
				NewRow.Id = Search[0].Id;
				NewRow.FullNameOfTheIBUser = Search[0].FullName;
				NewRow.Right = ?(Result.Role = OwnerRole(), LaunchAndAdministrationRights(), RightToStart());
				NewRow.User = Search[0].User;
				AddUnmappedUsersToList();
				UpdateUserMappingStatus();
			EndIf; 
		EndIf; 
		Items.UsersRights.CurrentRow = NewRow.GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillIBUsers()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Users.ServiceUserID AS ServiceUserID,
		|	Users.IBUserID AS IBUserID,
		|	Users.Description AS Description,
		|	Users.Ref AS User,
		|	MAX(UsersContactInformation.Presentation) AS Email
		|FROM
		|	Catalog.Users AS Users
		|		LEFT JOIN Catalog.Users.ContactInformation AS UsersContactInformation
		|		ON Users.Ref = UsersContactInformation.Ref
		|		AND (UsersContactInformation.Kind = &ViewEmailAddress)
		|WHERE
		|	NOT Users.IsInternal
		|GROUP BY
		|	Users.ServiceUserID,
		|	Users.IBUserID,
		|	Users.Description,
		|	Users.Ref
		|ORDER BY
		|	Description";
	
	Query.SetParameter("ViewEmailAddress", Catalogs.ContactInformationKinds.UserEmail);
	Result = Query.Execute();
	Selection = Result.Select();
	
	UserCache = New Map;
	
	IBUsers.Clear();
	SetPrivilegedMode(True);
	While Selection.Next() Do
		UserFromCache = UserCache[Selection.IBUserID];
		
		If UserFromCache = False Then
			IBUser = Undefined;
		ElsIf UserFromCache = Undefined Then
			IBUser = InfoBaseUsers.FindByUUID(Selection.IBUserID);
			If IBUser = Undefined Then
				UserCache[Selection.IBUserID] = False;
			Else
				UserCache[Selection.IBUserID] = IBUser;
			EndIf;
		Else
			IBUser = UserFromCache;
		EndIf;
		
		If IBUser = Undefined Then
			Continue;
		EndIf; 
		NewRow = IBUsers.Add();
		NewRow.User = Selection.User;
		NewRow.Id = Selection.User.UUID();
		NewRow.Email = Selection.Email;
		NewRow.Login = IBUser.Name;
		NewRow.FullName = IBUser.FullName;
	EndDo;
	IBUsers.Sort("FullName");
	
EndProcedure

&AtClient
Procedure ChoosingInformationSecurityUser(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		IBData = SelectedElement.Value; // FormDataCollectionItem 
		For Each TableRow In UsersRights Do
			If TableRow.Id = IBData.Id And ValueIsFilled(TableRow.Login) Then
				TableRow.Id = Undefined;
				TableRow.User = Undefined;
				TableRow.FullNameOfTheIBUser = Undefined;
				TableRow.Right = Undefined;
			EndIf;
		EndDo;
		
		CurrentData = Items.UsersRights.CurrentData;
		CurrentData.Id = IBData.Id;
		CurrentData.User = IBData.User;
		CurrentData.FullNameOfTheIBUser = 
			?(ValueIsFilled(IBData.FullName), IBData.FullName, IBData.Login);
		IBData.ServiceUserLogin = CurrentData.Login;
		For Each IBData In IBUsers Do
			If IBData.ServiceUserLogin = CurrentData.Login 
				And CurrentData.Id <> IBData.Id Then
				IBData.ServiceUserLogin = "";
			EndIf; 
		EndDo; 
		
		If Not ValueIsFilled(CurrentData.Right) Then
			CurrentData.Right = ?(CurrentData.ThisIsTheSubscriberOwner, LaunchAndAdministrationRights(), RightToStart());
		EndIf;
		
	EndIf;
	
	AddUnmappedUsersToList();
	UpdateUserMappingStatus();
	
EndProcedure

&AtClient
Procedure MatchUsers()
	
	For Each Item In IBUsers Do
		Item.ServiceUserLogin = Undefined;
	EndDo; 
	
	InformationSecuritySearch = IBUsers.FindRows(New Structure("Id", CurrentUserID));
	SearchService = UsersRights.FindRows(New Structure("Login", Login));
	
	If InformationSecuritySearch.Count() > 0 And SearchService.Count() > 0 Then
		SearchService[0].Id = InformationSecuritySearch[0].Id;
		SearchService[0].Right = ?(SearchService[0].ThisIsTheSubscriberOwner, LaunchAndAdministrationRights(), RightToStart());
		SearchService[0].FullNameOfTheIBUser = InformationSecuritySearch[0].FullName;
		InformationSecuritySearch[0].ServiceUserLogin = SearchService[0].Login;
	EndIf; 
	
	For Each String In UsersRights Do
		If ValueIsFilled(String.Id) Then
			Continue;
		EndIf; 
		Search = IBUsers.FindRows(New Structure("Login", String.Login));
		If Search.Count() > 0 And Not ValueIsFilled(Search[0].ServiceUserLogin) Then
			String.Id = Search[0].Id;
			String.Right = ?(String.ThisIsTheSubscriberOwner, LaunchAndAdministrationRights(), RightToStart());
			String.FullNameOfTheIBUser = Search[0].FullName;
			String.User = Search[0].User;
			Search[0].ServiceUserLogin = String.Login;
		EndIf;
		Search = IBUsers.FindRows(New Structure("FullName", String.FullName));
		If Search.Count() > 0 And Not ValueIsFilled(Search[0].ServiceUserLogin) Then
			String.Id = Search[0].Id;
			String.Right = ?(String.ThisIsTheSubscriberOwner, LaunchAndAdministrationRights(), RightToStart());
			String.FullNameOfTheIBUser = Search[0].FullName;
			String.User = Search[0].User;
			Search[0].ServiceUserLogin = String.Login;
		EndIf;
	EndDo;
	
	AddUnmappedUsersToList();
		
EndProcedure

&AtClient
Procedure AddUnmappedUsersToList()
	
	Search = UsersRights.FindRows(New Structure("FullName", ""));
	For Each String In Search Do
		UsersRights.Delete(String);
	EndDo; 
	For Each String In IBUsers Do
		If Not ValueIsFilled(String.ServiceUserLogin) Then
			NewRow = UsersRights.Add();
			NewRow.Id = String.Id;
			NewRow.User = String.User;
			NewRow.FullNameOfTheIBUser = String.FullName;
			NewRow.Email = String.Email;
			NewRow.Hyperlink = NStr("vi = 'Thêm';
									|ru = 'Добавить';
									|en = 'Add'; fa = 'افزودن';
									|it = 'Aggiungere';
									|pl = 'Add';
									|tr = 'Ekle'");
		EndIf; 
	EndDo; 
	
EndProcedure

&AtClient
Procedure UpdateUserMappingStatus()
	
	Matched = 0;
	For Each Item In IBUsers Do
		If ValueIsFilled(Item.ServiceUserLogin) Then
			Matched = Matched + 1;
		EndIf; 	
	EndDo; 
	
	Items.MappingStatus.Title = StrTemplate(
		NStr("vi = 'Đã so sánh: %1 trong số %2 người sử dụng';
			|ru = 'Сопоставлено пользователей: %1 из %2';
			|en = 'Users mapped: %1 out of %2'; fa = 'Users mapped: %1 out of %2';
			|it = 'Utenti associati: %1 di %2';
			|pl = 'Porównano użytkowników: %1 z %2';
			|tr = 'Eşleştirilen kullanıcılar: %1/%2'"), Matched, IBUsers.Count()); 
	
EndProcedure

#EndRegion 

#Region DataTransferToService

&AtClient 
Procedure StartDataTransfer(CurrentPage)
	
	FileNameAtClient = GetDataExportFileName(ExportModeForTechnicalSupport);
	
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Login", Login);
	QueryOptions.Insert("Password", Password);
	QueryOptions.Insert("SubscriberCode", SubscriberCode);
	QueryOptions.Insert("FileName", FileNameAtClient);
	QueryOptions.Insert("TemporaryStorageFileName", TemporaryStorageFileName);
	QueryOptions.Insert("FileSize", UploadFileSize);

	StartFileTransfer(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = HeaderUploadingData();
	IdleParameters.StateDescription = NStr("vi = 'Chuyển dữ liệu vào dịch vụ...';
											|ru = 'Передача данных в сервис...';
											|en = 'Transferring data to the service…'; fa = 'Transferring data to the service…';
											|it = 'Trasmissione dati nel servizio...';
											|pl = 'Przekazanie danych do serwisu...';
											|tr = 'Servise veri transferi...'");
	IdleParameters.AcceptableWaitingTime = 15;
	SetWaitingPage(CurrentPage, IdleParameters);

EndProcedure

&AtServerNoContext
Procedure StartFileTransfer(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	HandlerResults_1 = "Attachable_AfterTransferringFile";
	StartBackgroundJobOnServer("TransferFile_", QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtClient
Procedure Attachable_AfterTransferringFile(Result, AdditionalParameters) Export
	
	If HasErrors(Result) Then
		Return;
	EndIf; 
	
	FileID = Result.FileID;
	
	CreateApplicationFromFile();
	
EndProcedure

&AtClient
Procedure CreateApplicationFromFile()
	
	SetDefaultControls();
	
	QueryOptions = TemplateForQueryParameters();
	QueryOptions.Insert("Login", Login);
	QueryOptions.Insert("Password", Password);
	QueryOptions.Insert("SubscriberCode", SubscriberCode);
	QueryOptions.Insert("Method", "usr/tenant/create_from_data_dump");
	QueryOptions.Insert("HandlerResults_1", "Attachable_AfterCreatingApplication");
	QueryOptions.Insert("Timeout", 60);

	Data = New Structure;
	Data.Insert("file_id", FileID);
	Data.Insert("name", ApplicationDescription);
	Data.Insert("timezone ", TimeZone);
	
	ApplicationUsers = New Array;
	For Each String In UsersRights Do
		If ValueIsFilled(String.Right) Then
			ApplicationUser = New Structure;
			ApplicationUser.Insert("login", String.Login);
			ApplicationUser.Insert("role", String.Right);
			ApplicationUser.Insert("user_id", String(String.Id));
			ApplicationUsers.Add(ApplicationUser);
		EndIf; 
	EndDo; 
	Data.Insert("users", ApplicationUsers); 
	QueryOptions.Insert("Data", Data);
	
	StartExecutingInterfaceMethod(QueryOptions, HandlerResults_1, StorageAddress, JobID);
	
	IdleParameters = WaitingParametersTemplate();
	IdleParameters.PageHeader = HeaderUploadingData();
	IdleParameters.StateDescription = NStr("vi = 'Tạo ứng dụng...';
											|ru = 'Создание приложения...';
											|en = 'Creating an application…'; fa = 'Creating an application…';
											|it = 'Creazione dell''applicazione...';
											|pl = 'Utworzenie aplikacji...';
											|tr = 'Uygulama oluşturma...'");
	IdleParameters.AcceptableWaitingTime = 5;
	
	SetWaitingPage(Items.Pages.CurrentPage, IdleParameters);
	
EndProcedure

&AtClient
Procedure Attachable_AfterCreatingApplication(Result, AdditionalParameters) Export
	
	If HasErrors(Result) Then
		HeaderParts = New Array;
		HeaderParts.Add(NStr("vi = 'Không thể tạo ứng dụng do nguyên nhân:';
							|ru = 'Не удалось создать приложение по причине:';
							|en = 'Cannot create an application due to:'; fa = 'Cannot create an application due to:';
							|it = 'Non è stato possibile creare l''applicazione a causa di:';
							|pl = 'Nie udało się utworzyć aplikacji z powodu:';
							|tr = 'Uygulama bu sebepten oluşturulamadı:'"));
		HeaderParts.Add(Chars.LF);
		HeaderParts.Add(Items.StatusText_3.Title);
		HeaderParts.Add(Chars.LF);
		HeaderParts.Add(New FormattedString(
			NStr("vi = 'Thử lại';
				|ru = 'Повторить попытку';
				|en = 'Retry'; fa = 'تلاش مجدد';
				|it = 'Ripetere il tentativo';
				|pl = 'Powtórz próbę';
				|tr = 'Denemeyi tekrarla'"),,,, RetryAppCreationLink())); 
		Items.StatusText_3.Title = New FormattedString(HeaderParts);
		Return;
	EndIf; 
	
	DeleteTemporaryDataAfterSaving();	
	SetPageCompletion(Items.Pages.CurrentPage);
	
EndProcedure

#EndRegion

&AtServerNoContext
Procedure StartBackgroundJobOnServer(MethodName, QueryOptions, StorageAddress, JobID)
	
	ProcessingParameters_ = New Structure;
	If MethodName = "GetInformationAboutTransitionOptions" Then
		ProcessingParameters_.Insert("Address", QueryOptions.ServiceAddress);
		ProcessingParameters_.Insert("MethodInformation", QueryOptions.MethodInformation);
		ProcessingParameters_.Insert("LoadingOptionsMethod", QueryOptions.LoadingOptionsMethod);
	ElsIf MethodName = "GetData" Then
		ProcessingParameters_.Insert("Address", QueryOptions.ServiceAddress);
		ProcessingParameters_.Insert("Method", QueryOptions.Method);
	ElsIf MethodName = "SendData" Then
		ProcessingParameters_.Insert("Address", QueryOptions.ServiceAddress);
		ProcessingParameters_.Insert("Method", QueryOptions.Method);
		ProcessingParameters_.Insert("Data", QueryOptions.Data);
	ElsIf MethodName = "ExecuteExternalInterfaceMethod" Then
		ProcessingParameters_.Insert("APIAddress", QueryOptions.APIAddress);
		ProcessingParameters_.Insert("SoftwareInterfaceVersion", QueryOptions.SoftwareInterfaceVersion);
		ProcessingParameters_.Insert("Authorization", QueryOptions.Authorization);
		ProcessingParameters_.Insert("Method", QueryOptions.Method);
		ProcessingParameters_.Insert("Data", QueryOptions.Data);
	ElsIf MethodName = "TransferFile_" Or MethodName = "CheckPlusExtensions" Then
		ProcessingParameters_ = QueryOptions;
	EndIf; 
	
	DataProcessorName = "WizardOfTransitionToCloud";
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorName", DataProcessorName);
	JobParameters.Insert("MethodName", MethodName);
	JobParameters.Insert("ExecutionParameters", ProcessingParameters_);
	JobParameters.Insert("IsExternalDataProcessor", False);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(QueryOptions.Key);
	ExecutionParameters.BackgroundJobDescription = StrTemplate("WizardOfTransitionToCloud.%1", MethodName);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0.4;
	ExecutionParameters.Insert("FormIdentifier", QueryOptions.Key); 
	
	MethodToExecute = "TimeConsumingOperations.RunDataProcessorObjectModuleProcedure";
	Result = TimeConsumingOperations.ExecuteInBackground(MethodToExecute, JobParameters, ExecutionParameters);
	
	StorageAddress = Result.ResultAddress;
	JobID = Result.JobID;
	
EndProcedure

&AtClient
Procedure CheckQueryResult()
	
	Notification = New CallbackDescription(HandlerResults_1, ThisObject);
	Result = CheckQueryResultOnServer(JobID, StorageAddress);
	If Result = Undefined Then
		WaitingCounter = WaitingCounter + 1;
		If AcceptableWaitingTime > 0 And WaitingCounter > AcceptableWaitingTime Then
			Items.StatusText_3.Title = TextQuery();
		EndIf; 
		AttachIdleHandler("CheckQueryResult", 1, True);
	Else
		RunCallback(Notification, Result);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckQueryResultOnServer(JobID, StorageAddress)
	
	FederalLaw = BackgroundJobs.FindByUUID(JobID);
	
	If FederalLaw <> Undefined And FederalLaw.State = BackgroundJobState.Active Then
		Return Undefined;
		
	ElsIf FederalLaw <> Undefined And FederalLaw.State = BackgroundJobState.Completed Then
		Return GetFromTempStorage(StorageAddress);
	ElsIf FederalLaw <> Undefined And FederalLaw.State = BackgroundJobState.Failed Then
		ErrorText = CloudTechnology.DetailedErrorText(FederalLaw.ErrorInfo);
		Messages = FederalLaw.GetUserMessages();
		For Each Message In Messages Do
			ErrorText = Message.Text + Chars.LF + ErrorText;
		EndDo;
		Raise ErrorText;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Function HasErrors(Result)
	
	If Result.Error Then
		ShowErrorOnWaitingPage(Result.ErrorMessage);
		Return True
	EndIf;
	Data = Result.Data;
	If TypeOf(Data) = Type("Structure") And Data.Property("general") And Data.general.error Then
		ShowErrorOnWaitingPage(Data.general.message);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction
 
&AtServerNoContext
Procedure StartExecutingInterfaceMethod(QueryOptions, HandlerResults_1, StorageAddress, JobID)
	
	HandlerResults_1 = QueryOptions.HandlerResults_1;
	If QueryOptions.Property("SubscriberCode") Then
		Authorization = AuthorizationParameters(
			QueryOptions.Login, QueryOptions.Password, QueryOptions.SubscriberCode);
	Else
		Authorization = AuthorizationParameters(QueryOptions.Login, QueryOptions.Password);
	EndIf; 
	QueryOptions.Insert("Authorization", Authorization);
	
	If QueryOptions.Property("Data") Then
		If QueryOptions.Data.Property("sysname") Then
			QueryOptions.Data.sysname = Metadata.Name; 
		EndIf;
		If QueryOptions.Data.Property("sysversion") Then
			QueryOptions.Data.sysversion = Metadata.Version; 
		EndIf;
	Else		
		QueryOptions.Insert("Data", Undefined);
	EndIf; 
	
	StartBackgroundJobOnServer("ExecuteExternalInterfaceMethod", 
		QueryOptions, StorageAddress, JobID);
	
EndProcedure

&AtServerNoContext
Function AuthorizationParameters(Login, Password, SubscriberCode = Undefined)
	
	AuthorizationParameters = New Structure;
	AuthorizationParameters.Insert("Login", Login);
	AuthorizationParameters.Insert("Password", Password);
	If Not SubscriberCode = Undefined Then
		AuthorizationParameters.Insert("SubscriberCode", SubscriberCode);
	EndIf; 
	
	Return AuthorizationParameters;
	
EndFunction

&AtClient
Procedure ChoosingOrganizationCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		SPCode = Result.Code;
		SPCity = Result.City;
		SPDescription = Result.Description;
		SPSite = Result.Website1;
		SPPhone = Result.Phone;
		SPMail = Result.Mail;
		
		Items.ServiceOrganization.ChoiceList.Clear();
		Items.ServiceOrganization.ChoiceList.Add(SPCode, SPDescription);
			
	EndIf; 
	
EndProcedure

&AtClient
Procedure WhenChangingTransitionMethod()
	
	If TransitionMethod = UploadMethod() Then
		Items.DataUploadGroup.BackColor = ColorSelected();
		Items.MigrationGroup.BackColor = ?(MigrationIsAvailable, ColorNotSelected(), ColorNotAvailable());
	Else
		Items.MigrationGroup.BackColor = ColorSelected();
		Items.DataUploadGroup.BackColor = ColorNotSelected();
	EndIf;

EndProcedure

&AtClient
Procedure WhenChangingTransitionMethodOnMainPage()
	
	If TransitionMethod = UploadMethod() Then
		Items.VisualizationOfTheTransition.CurrentPage = Items.TheCloudPage;
		CheckServiceAddress();
	ElsIf TransitionMethod = MethodFile() Then
		Items.VisualizationOfTheTransition.CurrentPage = Items.FilePage;
		ShowStateEmpty(Items.CheckingTheServiceAddress.Name);
		Items.Next.Enabled = True;
	EndIf; 
	
EndProcedure

&AtClient
Procedure ShowErrorOnWaitingPage(ErrorMessage)
	
	ShowErrorState("StatePicture");
	Items.StatusText_3.Title = New FormattedString(ErrorMessage);
	Items.Next.Enabled = False;
	Items.Back.Enabled = True;

EndProcedure

&AtClient
Procedure ShowStateEmpty(TagName)
	
	Items[TagName].Picture = New Picture;
	
EndProcedure

&AtClient
Procedure ShowWaitingState(TagName)
	
	Items[TagName].Picture = Items.WaitPicture.Picture;
	
EndProcedure

&AtClient
Procedure ShowErrorState(TagName)
	
	Items[TagName].Picture = Items.StatusErrorPicture.Picture;
	
EndProcedure

&AtClient
Procedure ShowStateReady(TagName)
	
	Items[TagName].Picture = Items.PictureDone.Picture;
	
EndProcedure

&AtClient
Function ServiceOrganizationContactLine()
	
	SiteLink = ?(StrFind(SPSite, "http") = 0, "http://" + SPSite, SPSite);
	
	TitleFont = New Font(,, True);
	TextFont = New Font(,,,,,,90);
	
	Contacts = New Array;
	Contacts.Add(New FormattedString(SPDescription, TitleFont));
	Contacts.Add(New FormattedString(Chars.LF));
	If ValueIsFilled(SPCity) Then
		Contacts.Add(New FormattedString(SPCity, TextFont));
		Contacts.Add(New FormattedString("   ", TextFont));
	EndIf;
	If ValueIsFilled(SPPhone) Then
		AddContactPhone(Contacts, SPPhone, TextFont);
	EndIf; 
	Contacts.Add(New FormattedString(Chars.LF, TextFont));
	If ValueIsFilled(SPMail) Then
		AddContactMail(Contacts, SPMail, TextFont);
	EndIf;
	If ValueIsFilled(SPSite) Then
		Contacts.Add(New FormattedString(NStr("vi = 'Website:';
												|ru = 'Сайт:';
												|en = 'Website:'; fa = 'Website:';
												|it = 'Sito:';
												|pl = 'Website:';
												|tr = 'Web sitesi:'") , TextFont));
		Contacts.Add(New FormattedString(" ", TextFont));
		Contacts.Add(New FormattedString(SPSite, TextFont,,, SiteLink));
	EndIf; 
	
	Return New FormattedString(Contacts);
	
EndFunction 

&AtClient
Function OrganizationAutoSelectionLine()
	
	TitleFont = New Font(,, True);
	TextFont = New Font(,,,,,,90);
	
	HeaderComposition = New Array;
	HeaderComposition.Add(New FormattedString(
		NStr("vi = 'Chưa chọn doanh nghiệp dịch vụ.';
			|ru = 'Обслуживающая организация не выбрана.';
			|en = 'Service provider is not selected.'; fa = 'Service provider is not selected.';
			|it = 'Azienda di servizio non selezionata.';
			|pl = 'Firma obsługująca nie jest wybrana.';
			|tr = 'Hizmet veren iş yeri seçili değil.'"), TitleFont));
	HeaderComposition.Add(New FormattedString(Chars.LF));
	HeaderComposition.Add(New FormattedString(
		NStr("vi = 'Bản thân chúng tôi sẽ chỉ định một doanh nghiệp dịch vụ sẽ giúp bạn khi làm việc trong dịch vụ.';
			|ru = 'Мы сами назначим обслуживающую организацию, которая будет помогать Вам при работе в сервисе.';
			|en = 'We will assign you a service provider that will help you use the service.'; fa = 'We will assign you a service provider that will help you use the service.';
			|it = 'Ti verrà assegnata un''azienda di servizio che fornirà assistenza nell''utilizzo del servizio.';
			|pl = 'Sami wybierzemy firmę obsługującą, która będzie pomagać Ci podczas pracy w serwisie.';
			|tr = 'Serviste çalışırken size yardımcı olacak hizmet iş yeri atayacağız.'")));
	If ValueIsFilled(ProviderPhoneNumber) Or ValueIsFilled(MailProvider) Then
		HeaderComposition.Add(New FormattedString(Chars.LF));
		HeaderComposition.Add(New FormattedString(NStr("vi = 'Dịch vụ hỗ trợ:';
														|ru = 'Служба поддержки:';
														|en = 'Technical support:'; fa = 'Technical support:';
														|it = 'Servizio di assistenza:';
														|pl = 'Służba pomocy:';
														|tr = 'Destek hizmeti:'")));
		HeaderComposition.Add(" ");
	EndIf; 	
	If ValueIsFilled(ProviderPhoneNumber) Then
		AddContactPhone(HeaderComposition, ProviderPhoneNumber, TextFont);
	EndIf; 
	If ValueIsFilled(MailProvider) Then
		AddContactMail(HeaderComposition, MailProvider, TextFont);
	EndIf;
	
	Return New FormattedString(HeaderComposition);

EndFunction

&AtClient
Function SupportContactLine()
	
	TitleFont = New Font(,, True);
	TextFont = New Font(,,,,,,90);
	HeaderComposition = New Array;
	HeaderComposition.Add(New FormattedString(NStr("vi = 'Dịch vụ hỗ trợ';
													|ru = 'Служба поддержки';
													|en = 'Technical support'; fa = 'Technical support';
													|it = 'Servizio di assistenza';
													|pl = 'Służba pomocy';
													|tr = 'Destek hizmeti'"), TitleFont));
	HeaderComposition.Add(New FormattedString(Chars.LF));
	If ValueIsFilled(ProviderPhoneNumber) Then
		AddContactPhone(HeaderComposition, ProviderPhoneNumber, TextFont);
	EndIf; 
	If ValueIsFilled(MailProvider) Then
		AddContactMail(HeaderComposition, MailProvider, TextFont);
	EndIf;
	
	Return New FormattedString(HeaderComposition);
	
EndFunction

&AtClient
Procedure AddContactPhone(HeaderComposition, ContactPhone, Val TextFont)
	
	PhoneLink = "tel: " + NumbersOnly(ContactPhone);
	HeaderComposition.Add(New FormattedString(NStr("vi = 'đt.:';
													|ru = 'тел.:';
													|en = 'phone:'; fa = 'phone:';
													|it = 'tel.:';
													|pl = 'phone:';
													|tr = 'tel.:'") , TextFont));
	HeaderComposition.Add(New FormattedString(" ", TextFont));
	HeaderComposition.Add(New FormattedString(ContactPhone + " ", TextFont,,, PhoneLink));
	HeaderComposition.Add(New FormattedString("   ", TextFont));

EndProcedure

&AtClient
Procedure AddContactMail(HeaderComposition, ContactMail, Val TextFont)
	
	MailLink = "mailto: " + ContactMail;
	HeaderComposition.Add(New FormattedString(NStr("vi = 'e-mail:';
													|ru = 'e-mail:';
													|en = 'e-mail:'; fa = 'e-mail:';
													|it = 'e-mail:';
													|pl = 'e-mail:';
													|tr = 'e-mail:'") , TextFont));
	HeaderComposition.Add(New FormattedString(" ", TextFont));
	HeaderComposition.Add(New FormattedString(ContactMail, TextFont,,, MailLink));
	HeaderComposition.Add(New FormattedString("   ", TextFont));

EndProcedure

&AtClientAtServerNoContext
Function NumbersOnly(String)

	ProcessedString_ = "";

	For CharacterNumber = 1 To StrLen(String) Do
		Char = Mid(String, CharacterNumber, 1);
		If Char >= "0" And Char <= "9" Then
			ProcessedString_ = ProcessedString_ + Char;
		EndIf;
	EndDo;

	Return ProcessedString_;

EndFunction

&AtClientAtServerNoContext
Function RefRegistration()
	
	Return "Registration";
	
EndFunction

&AtClientAtServerNoContext
Function RetryAppCreationLink()
	
	Return "RetryAppCreation";
	
EndFunction

&AtClientAtServerNoContext
Function RetryDataTransferLink()
	
	Return "RetryDataTransfer";
	
EndFunction
 
&AtClient
Procedure WhenChangingRegistrationOption()
	
	If CheckInOption <> OptionOoSelection() Then
		SPCode = 0;
		SPDescription = "";
	EndIf; 
	
EndProcedure

&AtClient
Function WaitingParametersTemplate()
	
	IdleParameters = New Structure;
	IdleParameters.Insert("PageHeader", );
	IdleParameters.Insert("DescriptionOfWaiting", "");
	IdleParameters.Insert("StateDescription", "");
	IdleParameters.Insert("DisplayDescriptionTitle", False);
	IdleParameters.Insert("AcceptableWaitingTime", 0);
	
	Return IdleParameters;

EndFunction

&AtClient
Function TemplateForQueryParameters()
	
	Template = New Structure;
	Template.Insert("Key", UUID);
	Template.Insert("ServiceAddress", ServiceAddress);
	Template.Insert("APIAddress", APIAddress);
	Template.Insert("SoftwareInterfaceVersion", SoftwareInterfaceVersion);
	
	Return Template;
	
EndFunction

&AtClientAtServerNoContext
Function DataUploadErrorDescriptionTemplate()
	
	Return NStr("vi = 'Khi kết xuất dữ liệu đã xảy ra lỗi: %1.';
				|ru = 'При выгрузке данных произошла ошибка: %1.';
				|en = 'An error occurred when exporting data: %1.'; fa = 'An error occurred when exporting data: %1.';
				|it = 'При выгрузке данных произошла ошибка: %1.';
				|pl = 'An error occurred when exporting data: %1.';
				|tr = 'Veriler dışa aktarılırken hata oluştu: %1.'") + Chars.LF + ErrorHint();
	
EndFunction

&AtClientAtServerNoContext
Function ErrorHint()
	
	Return NStr("vi = 'Đã xảy ra lỗi khi kết xuất dữ liệu: %1.
				|
				|Thông tin hỗ trợ mở rộng đã được ghi vào nhật ký sự kiện. 
				|Nếu không xác định được nguyên nhân lỗi, bạn hãy liên hệ với bộ phận hỗ trợ kỹ thuật,
				|đồng thời cung cấp cơ sở thông tin và kết xuất tệp nhật ký sự kiện để điều tra.';
				|ru = 'При выгрузке данных произошла ошибка: %1.
				|
				|Расширенная информация для службы поддержки записана в журнал регистрации. 
				|Если причина ошибки неизвестна, рекомендуется обратиться в службу технической поддержки, 
				|предоставив для расследования информационную базу и выгрузку журнала регистрации.';
				|en = 'An error occurred when exporting data: %1.
				|
				|Detailed information for the technical support is written to the event log. 
				|If the error cause is unknown, we recommend that you contact the technical support 
				|providing the infobase and the event log export file for investigation.'; fa = 'An error occurred when exporting data: %1.
				|
				|Detailed information for the technical support is written to the event log. 
				|If the error cause is unknown, we recommend that you contact the technical support 
				|providing the infobase and the event log export file for investigation.';
				|it = 'Durante il caricamento dei dati si è verificato un errore: %1. 
				|
				| Le informazioni dettagliate per il servizio di supporto sono registrate nel registro degli eventi. 
				|Se l''origine dell''errore è sconosciuta, si consiglia di rivolgersi al servizio di supporto tecnico
				| e di mettere a disposizione l''infobase e il caricamento del registro degli eventi per l''analisi.';
				|pl = 'Podczas przesyłania danych zaistniał błąd: %1.
				|
				|Rozszerzona informacja dla służby pomocy została zapisana do dziennika rejestracji.
				|Jeśli przyczyna błędu nie jest znana, zaleca się skontaktować się z pomocą techniczną, 
				|udzielając do zbadania bazę informacyjną i wyciąg z dziennika rejestracji.';
				|tr = 'Veriler dışa aktarılırken hata oluştu: %1.
				|
				|Gelişmiş destek bilgileri günlüğe kaydedilir. 
				|Hatanın nedeni bilinmiyorsa, araştırma için infobase ve günlük dışa aktarmayı sağlayarak 
				|teknik destek servisiyle iletişime geçmeniz önerilmektedir.'");
	
EndFunction

&AtClient
Procedure ShowFillInFlag(Value, NameOfAttributeElement)
	
	If ValueIsFilled(Value) Then
		ShowStateReady(NameOfAttributeElement);
	Else
		ShowStateEmpty(NameOfAttributeElement);
	EndIf; 
	
EndProcedure

&AtClient
Function TextQuery()
	
	Return NStr("vi = 'Truy vấn mất nhiều thời gian hơn bình thường...';
				|ru = 'Запрос выполняется дольше обычного...';
				|en = 'Query is taking longer than usual…'; fa = 'Query is taking longer than usual…';
				|it = 'Il processo richiede più tempo del solito...';
				|pl = 'Zapytanie jest wykonywane dłużej niż zwykle...';
				|tr = 'Sorgu normalden daha uzun sürüyor...'") ;
	
EndFunction

&AtClientAtServerNoContext
Function PresentationOfUserRights(Right)
	
	If Right = RightToStart() Then
		Return NStr("vi = 'Khởi động';
					|ru = 'Запуск';
					|en = 'Start'; fa = 'شروع';
					|it = 'Avvio';
					|pl = 'Uruchomienie';
					|tr = 'Başlat'");
	ElsIf Right = LaunchAndAdministrationRights() Then
		Return NStr("vi = 'Khởi động và quản trị';
					|ru = 'Запуск и администрирование';
					|en = 'Launch and administration'; fa = 'راه‌اندازی و مدیریت';
					|it = 'Avvio e amministrazione';
					|pl = 'Uruchomienie i administrowanie';
					|tr = 'Başlatma ve yönetim'");
	EndIf;

EndFunction

&AtServer
Procedure SetVisibilityByUpdateState()
	
	Items.GroupSettingsUpdateRequired.Visible = Not MigrationIsAvailable;
	Items.GroupUploadingAnUpdateIsRequired.Visible = Not MigrationIsAvailable;
	Items.MigrationGroupUpdateRequired.Visible = Not MigrationIsAvailable;
	Items.NoteTheIndentation.Visible = MigrationIsAvailable;
	Items.MigrationGroupHeader.Enabled = MigrationIsAvailable;
	Items.MigrationGroup.BackColor = ?(MigrationIsAvailable, ColorNotSelected(), ColorNotAvailable());
	Items.NoteTheUpgradeIsRequired.ExtendedTooltip.Title = StrTemplate(
		NStr("vi = 'Các phiên bản được hỗ trợ: %1';
			|ru = 'Поддерживаемые версии: %1';
			|en = 'Supported versions: %1'; fa = 'Supported versions: %1';
			|it = 'Versioni supportate: %1';
			|pl = 'Obsługiwane wersje: %1';
			|tr = 'Desteklenen sürümleri:%1'"), 
		StrConcat(SupportedVersionsForMigration.UnloadValues(), "; ")); 
		
	Items.GroupDataUploadHeader.Enabled = UploadIsAvailable;
	If Not UploadIsAvailable Then
		Items.GetTheUploadFile.ExtendedTooltip.Title = StrTemplate(
			NStr("vi = 'Phiên bản được hỗ trợ tối thiểu: %1';
				|ru = 'Минимальная поддерживаемая версия: %1';
				|en = 'Minimum supported version: %1'; fa = 'Minimum supported version: %1';
				|it = 'Versione minima supportata: %1';
				|pl = 'Minimalna obsługiwana wersja: %1';
				|tr = 'En düşük desteklenen sürüm: %1'"), TheMinimumVersionRequiredToDischarge);
	EndIf;
		
EndProcedure

&AtClient
Procedure BeforeClosingAlert(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CloseOfCourse = True;
		Close();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function OwnerRole()
	
	Return "owner";
	
EndFunction

&AtClientAtServerNoContext
Function RightToStart()
	
	Return "user";

EndFunction

&AtClientAtServerNoContext
Function LaunchAndAdministrationRights()
	
	Return "administrator";

EndFunction

&AtClientAtServerNoContext
Function OptionOoSelection()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function OptionAutomaticOoAssignment()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function OptionEnterActivationCode()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function UploadMethod()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function MethodMigration()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function MethodFile()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function OptionRequestForRegistration()
	
	Return 3;
	
EndFunction

&AtClientAtServerNoContext
Function TypeOfRegistrationRequest()
	
	Return "Approval"; // It is not localized.
	
EndFunction

&AtClientAtServerNoContext
Function TypeOfRegistrationInvitation()
	
	Return "Invitation"; // It is not localized.
	
EndFunction

&AtClientAtServerNoContext
Function TypeOfRegistrationManual()
	
	Return "Registration"; // It is not localized.
	
EndFunction

&AtClientAtServerNoContext
Function ColorSelected()
	
	// @skip-check new-color - a feature of the implementation.
	Return New Color(255, 255, 217);
	
EndFunction

&AtClientAtServerNoContext
Function ColorNotSelected()
	
	// @skip-check new-color - a feature of the implementation.
	Return New Color(255, 255, 254);
	
EndFunction

&AtClientAtServerNoContext
Function ColorNotAvailable()
	
	// @skip-check new-color - a feature of the implementation.
	Return New Color(250, 250, 250);
	
EndFunction

&AtServerNoContext
Function GetPart(StateID)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Id", StateID);
	Query.Text =
	"SELECT TOP 1
	|	ExportImportDataAreasParts.TemporaryStorageFileName AS TemporaryStorageFileName,
	|	ExportImportDataAreasParts.PartNumber AS PartNumber
	|FROM
	|	InformationRegister.ExportImportDataAreasParts AS ExportImportDataAreasParts
	|WHERE
	|	ExportImportDataAreasParts.Id = &Id
	|
	|ORDER BY
	|	PartNumber";
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Raise NStr("vi = 'Không tìm thấy phần kết xuất tiếp theo';
					|ru = 'Следующая часть выгрузки не обнаружена';
					|en = 'The next batch of data to export is not found.'; fa = 'The next batch of data to export is not found.';
					|it = 'Следующая часть выгрузки не обнаружена';
					|pl = 'The next batch of data to export is not found.';
					|tr = 'Dışa aktarmanın aşağıdaki bölümü bulunamadı'");
	EndIf;
	
	FileName = FilesCTL.FullTemporaryStorageFileName(Selection.TemporaryStorageFileName);
	BinaryData = New BinaryData(FileName);
	
	Record = InformationRegisters.ExportImportDataAreasParts.CreateRecordManager();
	Record.Id = StateID;
	Record.PartNumber = Selection.PartNumber;
	Record.Delete();
	FilesCTL.DeleteTemporaryStorageFile(Selection.TemporaryStorageFileName);
	
	Return BinaryData;
	
EndFunction

&AtServerNoContext
Function AppSizeLargerThanAllowed()
	
	SetPrivilegedMode(True);
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ApplicationsSize.Size AS Size
	|FROM
	|	InformationRegister.ApplicationsSize AS ApplicationsSize";
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Or Selection.Size = 0 Then
		Return False;
	EndIf;
	
	ApplicationSize = Selection.Size / 1024 / 1024;
		
	Return ApplicationSize > Constants.ApplicationMaximumSizeForExportWithoutFilesExtension.Value();
	
EndFunction

&AtClient
Function IsWebClient()
	
	#If WebClient Then
		Return True;
	#EndIf
	
	Return False;
	
EndFunction

#EndRegion

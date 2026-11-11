
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// Core
	AskConfirmationOnExit = StandardSubsystemsServer.AskConfirmationOnExit();
	ShowInstalledApplicationUpdatesWarning = StandardSubsystemsServer.ShowInstalledApplicationUpdatesWarning();
	// End Core
	
	// working with users
	CurrentUser = Users.AuthorizedUser();	
	
	// Work with files
	PromptForEditModeOnOpenFile = 
		CommonSettingsStorage.Load("OpenFileSettings", "PromptForEditModeOnOpenFile");
	If PromptForEditModeOnOpenFile = Undefined Then
		PromptForEditModeOnOpenFile = True;
		CommonSettingsStorage.Save("OpenFileSettings", "PromptForEditModeOnOpenFile", PromptForEditModeOnOpenFile);
	EndIf;
	
	ActionOnDoubleClick = CommonSettingsStorage.Load("OpenFileSettings", "ActionOnDoubleClick");
	If ActionOnDoubleClick = Undefined Then
		ActionOnDoubleClick = Enums.DoubleClickFileActions.OpenFile;
		CommonSettingsStorage.Save("OpenFileSettings", "ActionOnDoubleClick", ActionOnDoubleClick);
	EndIf;
	
	FileVersionsComparisonMethod = CommonSettingsStorage.Load("FileComparisonSettings", "FileVersionsComparisonMethod");
	ShowTooltipsOnEditFiles = Common.CommonSettingsStorageLoad("ApplicationSettings", "ShowTooltipsOnEditFiles");
	ShowFileNotModifiedFlag = Common.CommonSettingsStorageLoad("ApplicationSettings", "ShowFileNotModifiedFlag");
	
	ShowLockedFilesOnExit =  Common.CommonSettingsStorageLoad("ApplicationSettings", "ShowLockedFilesOnExit");
	If ShowLockedFilesOnExit = Undefined Then 
		ShowLockedFilesOnExit = True;
		CommonSettingsStorage.Save("ApplicationSettings", "ShowLockedFilesOnExit", ShowLockedFilesOnExit);
	EndIf;
	
	ShowSizeColumn = CommonSettingsStorage.Load("ApplicationSettings", "ShowSizeColumn");
	If ShowSizeColumn = Undefined Then
		ShowSizeColumn = False;
		CommonSettingsStorage.Save("ApplicationSettings", "ShowSizeColumn", ShowSizeColumn);
	EndIf;
	
	// Filling in the file opening settings.
	FilesOperationSettings = FilesOperations.FilesOperationSettings();
	
	SettingString = OpenFileSettings.Add();
	SettingString.FileType = Enums.BuiltInEditorFileTypes.TextFiles;
	SettingString.Extension = FilesOperationSettings.TextFilesExtension;
	SettingString.OpeningMethod = FilesOperationSettings.TextFilesOpeningMethod;
	
	SettingString = OpenFileSettings.Add();
	SettingString.FileType = Enums.BuiltInEditorFileTypes.GraphicalSchemas;
	SettingString.Extension = FilesOperationSettings.GraphicalSchemasExtension;
	SettingString.OpeningMethod = FilesOperationSettings.GraphicalSchemasOpeningMethod;
	
	ShowRegistrationMessage = CommonSettingsStorage.Load("DocumentSettings_", "ShowRegistrationMessage");
	If ShowRegistrationMessage = Undefined Then 
		ShowRegistrationMessage = True;
		CommonSettingsStorage.Save("DocumentSettings_", "ShowRegistrationMessage", ShowRegistrationMessage);
	EndIf;
	
	Items.Group8.Visible = Users.IsFullUser(, True)
									And (Not Common.DataSeparationEnabled()
									Or Not Common.SeparatedDataUsageAvailable());
	
	// Filling out documents on statistics
	FillInAccordingToStatistics = CommonSettingsStorage.Load(
		"DocumentSettings_", "FillInDocumentAttributesUsingStatisticalData");
	If FillInAccordingToStatistics <> Undefined Then
		FillInDocumentAttributesUsingStatisticalData = FillInAccordingToStatistics;
	Else
		FillInDocumentAttributesUsingStatisticalData = True;
		CommonSettingsStorage.Save(
			"DocumentSettings_", "FillInDocumentAttributesUsingStatisticalData", True);
	EndIf;
	
	// Print
	RequestConfirmation = Common.CommonSettingsStorageLoad("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments");
	If RequestConfirmation <> Undefined Then
		RequestConfirmationWhenPrintingASetOfDocuments = RequestConfirmation;
	Else
		RequestConfirmationWhenPrintingASetOfDocuments = True;
		Common.CommonSettingsStorageSave("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments", True);
	EndIf;
	
	TurningOffResidueControlIsAvailable = UserRightsCached.AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration();
	
	If TurningOffResidueControlIsAvailable Then
		UpdateLabelOfDisableItemBalanceMonitoringButton(SessionParameters.PostWithoutControlOfCompanyStockBalance);
	EndIf;
	
	ItIsPossibleToDisableControlOfItemReservesForOrders = UserRightsCached.AllowDisablingOfTheControlOfGoodsReservesUnderOrdersForTheSessionDuration();
	
	If ItIsPossibleToDisableControlOfItemReservesForOrders Then
		UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
	EndIf;
	
	Items.DisableControlOfProductBalances.Visible = TurningOffResidueControlIsAvailable;
	Items.DisableMonitoringOfGoodsReservesOnOrders.Visible = ItIsPossibleToDisableControlOfItemReservesForOrders;
	
	If Not Common.SubsystemExists("IntegrationWith1CDocumentManagementSubsystem") Then
		Items.IntegrationWith1CDocumentManagement.Visible = False;
	EndIf;
	
	// Accounting for retro bonuses
	AllowDisablingRebatesBalanceCheckForSessionDuration = UserRightsCached.AllowDisablingRebatesBalanceCheckForSessionDuration();
	Items.TurnOffBalanceControlOfCustomersRebates.Visible = AllowDisablingRebatesBalanceCheckForSessionDuration;
	
	If AllowDisablingRebatesBalanceCheckForSessionDuration Then
		
		UpdateInscriptionOfButtonToTurnOffControlOfBalancesOfRebates(SessionParameters.PostWithoutRebateBalanceCheck);
		
	EndIf;
	
	// Salary And Personnel Accounting
	Items.SalaryAndPersonnelAccounting.Visible = GetFunctionalOption("UsePayrollTM");
	Items.PersonalSettingsChangeSignature.Visible =
		Common.SubsystemExists("SalaryPersonnelSubsystems.SignaturesOfDocuments");
	Items.ClearSettingsForSigningEDSPersonnelEDI.Visible =
		Common.SubsystemExists("SalaryPersonnelSubsystems.EDOBZK");
	
	// User Alerts About Events
	UpdateNotificationSettings();
	
EndProcedure

&AtClient
Procedure AskConfirmationOnExitOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	Notification = New CallbackDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
EndProcedure

&AtClient
Procedure OnClose(Exit)
		
	If Exit Then
		Return;
	EndIf;
	
	RecordAndUpdateProgramInterface();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ConversationsEnabled" Then
		
		UpdateNotificationSettings();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose()
	StructuresArray = New Array;
	
	// Work with files
	Item = New Structure;
	Item.Insert("Object", "OpenFileSettings");
	Item.Insert("Setting", "ActionOnDoubleClick");
	Item.Insert("Value", ActionOnDoubleClick);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "OpenFileSettings");
	Item.Insert("Setting", "PromptForEditModeOnOpenFile");
	Item.Insert("Value", PromptForEditModeOnOpenFile);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ApplicationSettings");
	Item.Insert("Setting", "ShowTooltipsOnEditFiles");
	Item.Insert("Value", ShowTooltipsOnEditFiles);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ApplicationSettings");
	Item.Insert("Setting", "ShowLockedFilesOnExit");
	Item.Insert("Value", ShowLockedFilesOnExit);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "FileComparisonSettings");
	Item.Insert("Setting", "FileVersionsComparisonMethod");
	Item.Insert("Value", FileVersionsComparisonMethod);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ApplicationSettings");
	Item.Insert("Setting", "ShowSizeColumn");
	Item.Insert("Value", ShowSizeColumn);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "DocumentSettings_");
	Item.Insert("Setting", "FillInDocumentAttributesUsingStatisticalData");
	Item.Insert("Value", FillInDocumentAttributesUsingStatisticalData);
	StructuresArray.Add(Item);
	
	If OpenFileSettings.Count() >= 1 Then
		
		Item = New Structure;
		Item.Insert("Object", "OpenFileSettings\TextFiles");
		Item.Insert("Setting", "Extension");
		Item.Insert("Value", OpenFileSettings[0].Extension);
		StructuresArray.Add(Item);
		
		Item = New Structure;
		Item.Insert("Object", "OpenFileSettings\TextFiles");
		Item.Insert("Setting", "OpeningMethod");
		Item.Insert("Value", OpenFileSettings[0].OpeningMethod);
		StructuresArray.Add(Item);
		
		Item = New Structure;
		Item.Insert("Object", "OpenFileSettings\GraphicalSchemas");
		Item.Insert("Setting", "Extension");
		Item.Insert("Value", OpenFileSettings[1].Extension);
		StructuresArray.Add(Item);
		
		Item = New Structure;
		Item.Insert("Object", "OpenFileSettings\GraphicalSchemas");
		Item.Insert("Setting", "OpeningMethod");
		Item.Insert("Value", OpenFileSettings[1].OpeningMethod);
		StructuresArray.Add(Item);
		
	EndIf;
	
	// Core
	StructuresArray.Add(SettingDetails(
	    "UserCommonSettings",
	    "AskConfirmationOnExit",
	    AskConfirmationOnExit));
	
	StructuresArray.Add(SettingDetails(
	    "UserCommonSettings",
	    "ShowInstalledApplicationUpdatesWarning",
	    ShowInstalledApplicationUpdatesWarning));
	// End Core
	
	StructuresArray.Add(SettingDetails(
	    "ApplicationSettings",
	    "ShowFileNotModifiedFlag",
	    ShowFileNotModifiedFlag));
	
	// Print
	StructuresArray.Add(SettingDetails(
		"UserCommonSettings",
		"RequestConfirmationWhenPrintingASetOfDocuments",
		RequestConfirmationWhenPrintingASetOfDocuments));
	// End Print
	
	CommonServerCall.CommonSettingsStorageSaveArray(StructuresArray);
	Modified = False;
	
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure WorkingDirectorySettings(Command)
	OpenForm("CommonForm.WorkingDirectorySettings",,,,,, Undefined, FormWindowOpeningMode.LockWholeInterface);
EndProcedure

&AtClient
Procedure InstallFileSystemExtensionAtClient(Command)
	BeginInstallFileSystemExtension(Undefined);
EndProcedure

&AtClient
Procedure ScanningSettings(Command)
	
	FilesOperationsClient.OpenScanSettingForm();
	
EndProcedure

&AtClient
Procedure UserInfo(Command)
	
	ShowValue(Undefined, CurrentUser);
	
EndProcedure

&AtClient
Procedure UpdateSystemParameters(Command)
	
	RefreshReusableValues();
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure SetActionOnChoosePrintFormTemplate(Command)
	OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode");
EndProcedure

&AtClient
Procedure ProxyServerCustomSettings(Command)
	
	OpenForm("CommonForm.ProxyServerParameters",
	                  New Structure("ProxySettingAtClient", True));
					  
EndProcedure

&AtClient
Procedure ConfigureDS(Command)
	
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings();
	
EndProcedure

&AtClient
Procedure InstallTheCryptographyExtensionOnTheClient(Command)
	BeginInstallCryptoExtension(Undefined);
EndProcedure

&AtClient
Procedure ConfigureAuthorizationParametersIn1WithDocumentFlow(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement",,,,,,
		Undefined,
		FormWindowOpeningMode.LockWholeInterface);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure DisableControlOfProductBalances(Command)
	DisableControlOfProductBalancesServer();
EndProcedure

&AtClient
Procedure DisableMonitoringOfGoodsReservesOnOrders(Command)
	
	DisableMonitoringOfGoodsReservesOnOrdersServer();
	
EndProcedure

&AtClient
Procedure TurnOffBalanceControlOfRebates(Command)
	
	TurnOffBalanceControlOfRebatesServer();
	
EndProcedure

&AtServer
Procedure DisableControlOfProductBalancesServer()
	SessionParameters.PostWithoutControlOfCompanyStockBalance = Not SessionParameters.PostWithoutControlOfCompanyStockBalance;
	
	UpdateLabelOfDisableItemBalanceMonitoringButton(SessionParameters.PostWithoutControlOfCompanyStockBalance);
	
	If SessionParameters.PostWithoutControlOfCompanyStockBalance Then
		MessageText = NStr("vi = 'Người dùng %UserName% trong khuôn khổ phiên của mình, đã tắt kiểm soát số dư hàng hóa của doanh nghiệp.';
							|ru = 'Пользователем %UserName% в рамках своего сеанса выключен контроль остатков товаров организаций.';
							|en = 'Control of company stock balance is disabled by the %UserName% user during their session.'; fa = 'Control of company stock balance is disabled by the %UserName% user during their session.';
							|it = 'Nell''ambito della propria sessione, l''utente %UserName% ha disattivato il controllo delle rimanenze merci delle società.';
							|pl = 'Użytkownik %UserName% w ramach swojej sesji włączył kontrolę stanu magazynowego firmy.';
							|tr = '%UserName% kullanıcısı, oturumu kapsamında iş yerlerinde stok bakiyelerinin kontrolünü devre dışı bıraktı.'", Metadata.DefaultLanguage.LanguageCode);
	Else
		MessageText = NStr("vi = 'Người sử dụng %UserName% đã khôi phục kiểm soát số dư hàng hóa trong doanh nghiệp.';
							|ru = 'Пользователем %UserName% возобновлен контроль остатков товаров организаций.';
							|en = 'Control of company stock balance is resumed by the %UserName% user'; fa = 'Control of company stock balance is resumed by the %UserName% user';
							|it = 'L''utente %UserName% ha ripristinato il controllo delle rimanenze merci delle società.';
							|pl = 'Użytkownik %UserName% wznowił kontrolę stanu magazynowego firmy.';
							|tr = '%UserName% kullanıcısı, iş yerlerinin ürün bakiye kontrolünü yeniden yürütmeye devam etti.'", Metadata.DefaultLanguage.LanguageCode);
	EndIf;
	MessageText = StrReplace(MessageText, "%UserName%", Users.CurrentUser());
	
	WriteLogEvent(InventoriesServer.EventNameResidueControlDisabled(),
		EventLogLevel.Warning, , ,MessageText);
EndProcedure

&AtClient
Procedure PromptForEditModeOnOpenFileOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure ShowTooltipsOnEditFilesOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure ShowLockedFilesOnExitOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure ShowSizeColumnOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure ShowFileNotModifiedFlagOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure FileVersionsComparisonMethodOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure RequestConfirmationWhenPrintingASetOfDocumentsOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure NotifyViaTelegramOnChange(Item)
	NotificationMethod = PredefinedValue("Enum.UserNotificationsMethods.Telegram");
	SaveUserNotificationSettings(NotificationMethod, NotifyViaTelegram);
	Items.ConnectingToTelegramBot.Enabled = NotifyViaTelegram;
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure ShouldNotifyByEmailOnChange(Item)
	NotificationMethod = PredefinedValue("Enum.UserNotificationsMethods.Email");
	SaveUserNotificationSettings(NotificationMethod, ShouldNotifyByEmail);
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure PersonalSettingsChangeSignature(Command)
	
	If CommonClient.SubsystemExists("SalaryPersonnelSubsystems.SignaturesOfDocuments") Then
		DocumentSigningModule = CommonClient.CommonModule("SignaturesOfDocumentsClient");
		DocumentSigningModule.OpenSignatureChangeSettingsForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearSettingsForSigningEDSPersonnelEDI(Command)
	
	If CommonClient.SubsystemExists("SalaryPersonnelSubsystems.EDOBZK") Then
		EDOBZKClientModule = CommonClient.CommonModule("EDOBZKClient");
		EDOBZKClientModule.ClearSettingsForSigningPrintedForms();
	EndIf;
	
EndProcedure

&AtClient
Procedure ReminderSettings(Command)
	
	ModuleUserReminderClient = CommonClient.CommonModule("UserRemindersClient");
	ModuleUserReminderClient.OpenSettings();
	
EndProcedure

&AtClient
Procedure EmailOperationSettings(Command)
	
	OpenForm("DocumentJournal.Interactions.Form.EmailOperationSettings",,ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure NotificationsSettings(Command)
	
	OpenForm("InformationRegister.DisabledUserNotificationSettings.Form.PersonalSettings");
	
EndProcedure

&AtClient
Procedure ConnectingToTelegramBot(Command)
	
	OpenForm("DataProcessor.ConnectingToUserNotificationsBot.Form.ConnectingToTelegramBot");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure RecordAndUpdateProgramInterface()
	WriteAndClose();
	CommonClient.RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure ActionOnDoubleClickOnChange(Item)
	RecordAndUpdateProgramInterface();
EndProcedure

&AtClient
Procedure WriteAndCloseNotification(Result, Var_Undefined) Export
	WriteAndClose();
EndProcedure

&AtClient
Function SettingDetails(Object, Setting, Value)
	
	Item = New Structure;
	Item.Insert("Object", Object);
	Item.Insert("Setting", Setting);
	Item.Insert("Value", Value);
	
	Return Item;
	
EndFunction

&AtServer
Procedure UpdateLabelOfDisableItemBalanceMonitoringButton(ControlDisabled)
	If ControlDisabled Then
		Items.DisableControlOfProductBalances.Title = NStr("vi = 'Khôi phục kiểm soát số dư';
															|ru = 'Возобновить контроль остатков';
															|en = 'Resume stock balance control'; fa = 'Resume stock balance control';
															|it = 'Ripristinare il controllo delle rimanenze merci';
															|pl = 'Wznów kontrolę ostatków';
															|tr = 'Bakiye kontrolünü yeniden yürüt'");
		Items.DisableControlOfProductBalances.ExtendedTooltip.Title = NStr("vi = 'Khôi phục kiểm soát số dư hàng hóa trái trong doanh nghiệp đối với người sử dụng hiện tại, mà trước đó đã tắt trong suốt phiên làm việc.';
																			|ru = 'Восстановление контроля остатков товаров организаций для текущего пользователя, ранее выключенных на время сеанса.';
																			|en = 'Restore company stock balance previously disabled for the session time for the current user.'; fa = 'بازگردانی کنترل مانده موجودی شرکت که قبلاً برای مدت جلسه برای کاربر فعلی غیرفعال شده بود.';
																			|it = 'Ripristino del controllo delle rimanenze merci delle società per l''utente corrente, precedentemente disabilitato per la durata della sessione.';
																			|pl = 'Odzyskiwanie kontroli pozostałości towarów firm dla bieżącego użytkownika, wcześniej wyłączonych na czas sesji.';
																			|tr = 'Oturum süresince daha önce devre dışı bırakılan mevcut kullanıcı için stok bakiyesinin kontrolünü geri yükleme.'");
	Else
		Items.DisableControlOfProductBalances.Title = NStr("vi = 'Ngắt kiểm soát số dư (trong phiên)';
															|ru = 'Отключить контроль остатков (на время сеанса)';
															|en = 'Disable stock balance control (for the session time)'; fa = 'غیرفعال کردن کنترل مانده موجودی (برای مدت جلسه)';
															|it = 'Disabilitare il controllo delle rimanenze (per la durata della sessione)';
															|pl = 'Wyłącz kontrolę pozostałości (na czas sesji)';
															|tr = 'Bakiye kontrolünü devre dışı bırak (oturum süresince)'");
		Items.DisableControlOfProductBalances.ExtendedTooltip.Title = NStr("vi = 'Ngắt kiểm soát số dư hàng hóa của doanh nghiệp cho người dùng hiện tại trong phiên làm việc.';
																			|ru = 'Выключение контроля остатков товаров организаций для текущего пользователя на время сеанса работы.';
																			|en = 'Disable company stock balance for the current user for the operation session time.'; fa = 'Disable company stock balance for the current user for the operation session time.';
																			|it = 'Disattivare il controllo dei saldi di magazzino delle aziende per l''utente corrente durante la sessione di lavoro.';
																			|pl = 'Wyłączenie kontroli stanu magazynowego firmy dla bieżącego użytkownika na czas sesji pracy.';
																			|tr = 'Oturum süresince geçerli kullanıcı için iş yerlerinin ürün bakiyesi üzerindeki kontrolün devre dışı bırakılması.'");
	EndIf;
EndProcedure

&AtServer
Procedure DisableMonitoringOfGoodsReservesOnOrdersServer()
	
	SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders = Not SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders;
	
	UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
	
	If SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders Then
		MessageText = NStr("vi = 'Người dùng %UserName% trong khuôn khổ phiên của mình, đã tắt kiểm soát dự phòng theo đơn hàng.';
							|ru = 'Пользователем %UserName% в рамках своего сеанса выключен контроль резервов по заказам.';
							|en = 'Control of reserves under orders is disabled by the %UserName% user during their session.'; fa = 'Control of reserves under orders is disabled by the %UserName% user during their session.';
							|it = 'Пользователем %UserName% в рамках своего сеанса выключен контроль резервов по заказам.';
							|pl = 'Control of reserves under orders is disabled by the %UserName% user during their session.';
							|tr = '%UserName% kullanıcısı, oturumu kapsamında sipariş rezervi kontrolünü devre dışı bıraktı.'",
			Common.DefaultLanguageCode());
	Else
		MessageText = NStr("vi = 'Đã khôi phục kiểm soát dự phòng theo đơn hàng bởi người sử dụng %UserName%.';
							|ru = 'Пользователем %UserName% возобновлен контроль резервов по заказам.';
							|en = 'Control of reserves under orders is resumed by the %UserName% user.'; fa = 'Control of reserves under orders is resumed by the %UserName% user.';
							|it = 'Пользователем %UserName% возобновлен контроль резервов по заказам.';
							|pl = 'Control of reserves under orders is resumed by the %UserName% user.';
							|tr = '%UserName% kullanıcısı, sipariş rezervi kontrolüne yeniden başladı.'",
			Common.DefaultLanguageCode());
	EndIf;
	MessageText = StrReplace(MessageText, "%UserName%", Users.CurrentUser());
	
	WriteLogEvent(ProvisionInDocumentsServer.EventNameMonitoringOfItemReservesForOrdersIsDisabled(),
		EventLogLevel.Warning, , , MessageText);
	
EndProcedure

&AtServer
Procedure UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(ControlDisabled)
	
	If ControlDisabled Then
		Items.DisableMonitoringOfGoodsReservesOnOrders.Title = NStr("vi = 'Khôi phục kiểm soát dự phòng';
																	|ru = 'Возобновить контроль резервов';
																	|en = 'Resume reserve control'; fa = 'Resume reserve control';
																	|it = 'Возобновить контроль резервов';
																	|pl = 'Resume reserve control';
																	|tr = 'Rezerv kontrolünü yeniden yürüt'");
		Items.DisableMonitoringOfGoodsReservesOnOrders.ExtendedTooltip.Title
			= NStr("vi = 'Khôi phục quyền kiểm soát dự phòng hàng hóa theo các đơn hàng đối với người sử dụng hiện tại mà đã tắt sử dụng trong suốt thời gian của phiên.';
					|ru = 'Восстановление контроля резервов товаров по заказам для текущего пользователя, ранее выключенных на время сеанса.';
					|en = 'Resume the control of reserves under orders previously disabled for the session time for the current user.'; fa = 'Resume the control of reserves under orders previously disabled for the session time for the current user.';
					|it = 'Восстановление контроля резервов товаров по заказам для текущего пользователя, ранее выключенных на время сеанса.';
					|pl = 'Resume the control of reserves under orders previously disabled for the session time for the current user.';
					|tr = 'Oturum süresince daha önce devre dışı bırakılan mevcut kullanıcı için siparişlere göre ürün rezervleri üzerindeki kontrolün yeniden sağlanması.'");
	Else
		Items.DisableMonitoringOfGoodsReservesOnOrders.Title = NStr("vi = 'Ngắt kiểm soát dự phòng (vào thời gian của phiên)';
																	|ru = 'Отключить контроль резервов (на время сеанса)';
																	|en = 'Disable reserve control (for the session time)'; fa = 'غیرفعال کردن کنترل رزرو (برای مدت جلسه)';
																	|it = 'Отключить контроль резервов (на время сеанса)';
																	|pl = 'Disable reserve control (for the session time)';
																	|tr = 'Rezerv kontrolünü devre dışı bırak (oturum süresince)'");
		Items.DisableMonitoringOfGoodsReservesOnOrders.ExtendedTooltip.Title
			= NStr("vi = 'Tắt kiểm soát dự phòng hàng hóa theo đơn hàng đối với người sử dụng hiện tại trong phiên làm việc.';
					|ru = 'Выключение контроля резервов товаров по заказам для текущего пользователя на время сеанса работы.';
					|en = 'Disable the control of goods reserves under orders for the current user for the operation session time.'; fa = 'Disable the control of goods reserves under orders for the current user for the operation session time.';
					|it = 'Выключение контроля резервов товаров по заказам для текущего пользователя на время сеанса работы.';
					|pl = 'Disable the control of goods reserves under orders for the current user for the operation session time.';
					|tr = 'Oturum süresince geçerli kullanıcı için siparişlere göre ürün rezervleri üzerindeki kontrolün devre dışı bırakılması.'");
	EndIf;
	
EndProcedure

&AtServer
Procedure TurnOffBalanceControlOfRebatesServer()
	
	SessionParameters.PostWithoutRebateBalanceCheck = Not SessionParameters.PostWithoutRebateBalanceCheck;
	
	UpdateInscriptionOfButtonToTurnOffControlOfBalancesOfRebates(SessionParameters.PostWithoutRebateBalanceCheck);
	
	If SessionParameters.PostWithoutRebateBalanceCheck Then
		MessageTemplate = NStr("vi = 'Người sử dụng %1 đã vô hiệu hóa kiểm soát số dư thưởng lũy kế trong khuôn khổ phiên làm việc của mình.';
								|ru = 'Пользователем %1 в рамках своего сеанса выключен контроль остатков ретро-бонусов.';
								|en = 'Rebate balance check is disabled by the %1 user during their session.'; fa = 'Rebate balance check is disabled by the %1 user during their session.';
								|it = 'Пользователем %1 в рамках своего сеанса выключен контроль остатков ретро-бонусов.';
								|pl = 'Rebate balance check is disabled by the %1 user during their session.';
								|tr = 'Kullanıcı %1, oturumunda retro-bonus bakiye kontrolünü kapattı.'", Common.DefaultLanguageCode());
	Else
		MessageTemplate = NStr("vi = 'Người sử dụng %1 đã khôi phục kiểm soát số dư thưởng lũy kế.';
								|ru = 'Пользователем %1 возобновлен контроль остатков ретро-бонусов.';
								|en = 'Rebate balance check is resumed by the %1 user.'; fa = 'Rebate balance check is resumed by the %1 user.';
								|it = 'Пользователем %1 возобновлен контроль остатков ретро-бонусов.';
								|pl = 'Rebate balance check is resumed by the %1 user.';
								|tr = 'Kullanıcı %1 retro-bonus bakiyelerinin kontrolünü yeniden üstlendi.'", Common.DefaultLanguageCode());
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		Users.CurrentUser());
	
	WriteLogEvent(
		RebatesServer.EventNameResidueControlDisabled(),
		EventLogLevel.Warning,
		,
		,
		MessageText);
	
EndProcedure

&AtServer
Procedure UpdateInscriptionOfButtonToTurnOffControlOfBalancesOfRebates(ControlDisabled)
	
	If ControlDisabled Then
		
		Items.TurnOffBalanceControlOfCustomersRebates.Title = NStr("vi = 'Khôi phục kiểm soát số dư thưởng lũy kế cho khách hàng';
																	|ru = 'Возобновить контроль остатков ретро-бонусов клиентов';
																	|en = 'Resume customer rebate balance check'; fa = 'Resume customer rebate balance check';
																	|it = 'Возобновить контроль остатков ретро-бонусов клиентов';
																	|pl = 'Resume customer rebate balance check';
																	|tr = 'Müşteri retro bonusu bakiyelerinin kontrolüne devam et'");
		Items.TurnOffBalanceControlOfCustomersRebates.ExtendedTooltip.Title = NStr("vi = 'Khôi phục kiểm soát số dư thưởng lũy kế đối với người sử dụng hiện tại đã từng bị vô hiệu hóa trong phiên làm việc.';
																					|ru = 'Восстановление контроля остатков ретро-бонусов клиентов для текущего пользователя, ранее выключенных на время сеанса.';
																					|en = 'Resume customer rebate balance check previously disabled for the session time for the current user.'; fa = 'Resume customer rebate balance check previously disabled for the session time for the current user.';
																					|it = 'Восстановление контроля остатков ретро-бонусов клиентов для текущего пользователя, ранее выключенных на время сеанса.';
																					|pl = 'Resume customer rebate balance check previously disabled for the session time for the current user.';
																					|tr = 'Mevcut kullanıcı için daha önce oturum açılırken devre dışı bırakılan müşteri retro bonusu bakiyelerinin kontrolünün geri yüklenmesi.'");
		
	Else
		
		Items.TurnOffBalanceControlOfCustomersRebates.Title = NStr("vi = 'Tắt sử dụng kiểm soát số dư thưởng lũy kế cho khách hàng (trong phiên làm việc)';
																	|ru = 'Отключить контроль остатков ретро-бонусов клиентов (на время сеанса)';
																	|en = 'Disable customer rebate balance check (for the session time)'; fa = 'غیرفعال کردن بررسی مانده تخفیف برگشتی مشتری (برای مدت جلسه)';
																	|it = 'Отключить контроль остатков ретро-бонусов клиентов (на время сеанса)';
																	|pl = 'Disable customer rebate balance check (for the session time)';
																	|tr = 'Müşteri retro bonusu bakiyelerinin kontrolünü devre dışı bırak (oturum esnasında)'");
		Items.TurnOffBalanceControlOfCustomersRebates.ExtendedTooltip.Title = NStr("vi = 'Tắt sử dụng kiểm soát số dư thưởng lũy kế cho khách hàng đối với người sử dụng hiện tại trong phiên làm việc.';
																					|ru = 'Выключение контроля остатков ретро-бонусов клиентов для текущего пользователя на время сеанса работы.';
																					|en = 'Disable customer rebate balance check for the current user for the operation session time.'; fa = 'Disable customer rebate balance check for the current user for the operation session time.';
																					|it = 'Выключение контроля остатков ретро-бонусов клиентов для текущего пользователя на время сеанса работы.';
																					|pl = 'Disable customer rebate balance check for the current user for the operation session time.';
																					|tr = 'Mevcut kullanıcı için devre dışı bırakılan müşteri retro bonusu bakiyelerinin kontrolünün kapatılması.'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateNotificationSettings()
	
	CollaborationSystemConnected = False;
	DiscussionSubsystemExists = False;
	If Common.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversations = Common.CommonModule("Conversations");
		CollaborationSystemConnected = ModuleConversations.CollaborationSystemConnected();
		DiscussionSubsystemExists = True;
	EndIf;
	
	Items.NotificationsSettings.Enabled = GetFunctionalOption("UseUserNotificationsOfSystemEvents");;
	Items.NotifyViaTelegram.Enabled = CollaborationSystemConnected And GetFunctionalOption("UseUserNotificationsViaTelegram");
	Items.ShouldNotifyByEmail.Enabled = CollaborationSystemConnected And GetFunctionalOption("UseUserNotificationsByEmail");
	
	NotificationsSettings = UserNotificationsOfEvents.SettingsByNotificationRecipient(CurrentUser);
	NotifyViaTelegram = NotificationsSettings.NotifyViaTelegram;
	ShouldNotifyByEmail = NotificationsSettings.ShouldNotifyByEmail;
	
	Items.ConnectingToTelegramBot.Enabled = NotifyViaTelegram And Items.NotifyViaTelegram.Enabled;
	
EndProcedure

&AtServer
Procedure SaveUserNotificationSettings(NotificationsMethod, Use)
	UserNotificationsOfEvents.SaveUserNotificationSettings(CurrentUser, 
		NotificationsMethod,
		Use);
EndProcedure

#EndRegion

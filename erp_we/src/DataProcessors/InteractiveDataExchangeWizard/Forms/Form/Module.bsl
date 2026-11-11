///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// There are two ways to parameterize a form:
//
// Option 1
//     
//         
//         
//                                                                 
//
// 
//     Parameters: 
//         InfobaseNodeCode - String - Exchange plan node code, for which the wizard will be opened.
//         ExchangePlanName - String - Name of an exchange plan to use for searching an exchange plan node whose code is specified in the InfobaseNodeCode parameter.
//                                                                 ExportAdditionExtendedMode - Boolean - Flag indicating whether the export addition setup by node scenario is enabled.
//                                                                 
//         
//                                                                 
//

#Region Variables

&AtClient
Var SkipCurrentPageCancelControl;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsStartedFromAnotherApplication = False;
	
	Parameters.Property("IsExchangeWithApplicationInService", ExchangeBetweenSaaSApplications);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	If Parameters.Property("InfobaseNode", Object.InfobaseNode) Then
		
		Object.ExchangePlanName = DataExchangeCached.GetExchangePlanName(Object.InfobaseNode);
		
	ElsIf Parameters.Property("InfobaseNodeCode") Then
		
		IsStartedFromAnotherApplication = True;
		
		Object.InfobaseNode = DataExchangeServer.ExchangePlanNodeByCode(
			Parameters.ExchangePlanName, Parameters.InfobaseNodeCode);
		
		If Not ValueIsFilled(Object.InfobaseNode) Then
			Raise NStr("vi = 'Không tìm thấy tùy chỉnh trao đổi dữ liệu.';
						|ru = 'Настройка обмена данными не найдена.';
						|en = 'The data exchange setting is not found.'; fa = 'The data exchange setting is not found.';
						|it = 'Configurazione di scambio dati non è stata trovata.';
						|pl = 'Nie znaleziono ustawienia wymiany danych.';
						|tr = 'Veri değişimi ayarı bulunmadı.'");
		EndIf;
		
		Object.ExchangePlanName = Parameters.ExchangePlanName;
		
	Else
		
		Raise NStr("vi = 'Không thể mở trực tiếp trợ giúp.';
					|ru = 'Непосредственное открытие помощника не предусмотрено.';
					|en = 'Cannot open this wizard directly.'; fa = 'Cannot open this wizard directly.';
					|it = 'L''apertura diretta dell''assistente non è prevista.';
					|pl = 'Bezpośrednie otwieranie asystenta nie jest przewidziane.';
					|tr = 'Sihirbaz açılamıyor.'");
		
	EndIf;
	
	InitializeExchangeMessagesTransportSettings();
	
	If Not ValueIsFilled(Object.TransportID) Then
		
		Text = NStr("vi = 'Chưa xác định tùy chỉnh kết nối mặc định. Không thể tiếp tục đồng bộ.';
					|ru = 'Не заданы настройки подключения. Синхронизация не может быть продолжена.';
					|en = 'Default connection settings are not configured. Synchronization is aborted.'; fa = 'Default connection settings are not configured. Synchronization is aborted.';
					|it = 'Не заданы настройки подключения. Синхронизация не может быть продолжена.';
					|pl = 'Default connection settings are not configured. Synchronization is aborted.';
					|tr = 'Varsayılan Bağlantı ayarları yapılandırılmamış. Senkronizasyon devam edemiyor.'", 
			Common.DefaultLanguageCode());
		
		Raise Text;
		
	EndIf;
	
	// Interactive data exchange is supported only for universal exchanges.
	If Not DataExchangeCached.IsUniversalDataExchangeNode(Object.InfobaseNode) Then
		Raise NStr("vi = 'Đối với nút đã chọn không thể thực hiện trao đổi dữ liệu có tùy chỉnh.';
					|ru = 'Для выбранного узла выполнение обмена данными с настройкой не предусмотрено.';
					|en = 'The selected node does not support settings-based data exchange.'; fa = 'The selected node does not support settings-based data exchange.';
					|it = 'Per il nodo selezionato, lo scambio dei dati con l''impostazione non è previsto.';
					|pl = 'Dla wybranego węzła wykonanie wymiany danych z ustawieniem nie jest przewidziane.';
					|tr = 'Seçilen ünite için ayar ile veri değişimi uygulaması gerekli değildir.'");
	EndIf;
	
	// Check whether exchange settings match the filter.
	AllNodes = DataExchangeCached.ExchangePlanNodes(Object.ExchangePlanName);
	If AllNodes.Find(Object.InfobaseNode) = Undefined Then
		Raise NStr("vi = 'Đối với nút đã chọn, không cho phép so sánh dữ liệu.';
					|ru = 'Для выбранного узла сопоставление данных не предусмотрено.';
					|en = 'The selected node does not provide data mapping.'; fa = 'The selected node does not provide data mapping.';
					|it = 'Per il nodo selezionato, l''associazione dei dati non è prevista.';
					|pl = 'Dla wybranego węzła porównanie danych nie jest przewidziane.';
					|tr = 'Seçilen ünite için ayar ile veri eşlenmesi gerekli değildir.'");
	EndIf;
	
	MessageReceivedForDataMapping = DataExchangeServer.MessageWithDataForMappingReceived(Object.InfobaseNode);
	
	If Not Parameters.Property("GetData", GetData) Then
		GetData = True;
	EndIf;
	
	If Not Parameters.Property("SendData", SendData) Then
		SendData = True;
	EndIf;
	
	If MessageReceivedForDataMapping Then
		SendData = False;
	EndIf;
	
	If Not GetData And Not SendData And Not MessageReceivedForDataMapping Then
		Raise NStr("vi = 'Không hỗ trợ kịch bản đồng bộ dữ liệu đã đặt.';
					|ru = 'Заданный сценарий синхронизации данных не поддерживается.';
					|en = 'The data synchronization scenario is not supported.'; fa = 'The data synchronization scenario is not supported.';
					|it = 'Lo scenario di sincronizzazione dati impostato non è supportato.';
					|pl = 'Określony scenariusz synchronizacji danych nie jest obsługiwany.';
					|tr = 'Bu veri senkronizasyon senaryosu desteklenmiyor.'");
	EndIf;
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
		
	Parameters.Property("TransportID", Object.TransportID);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	Parameters.Property("ExportAdditionMode",            ExportAdditionMode);
	Parameters.Property("AdvancedExportAdditionMode", ExportAdditionExtendedMode);
	
	CheckVersionDifference = True;
	
	PeerInfobaseName = String(Object.InfobaseNode);
	
	SetFormHeader();
	
	Items.DeleteMessageForMappingDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi khởi động thông điệp để so sánh, đã xảy ra lỗi.
		|Nên kết xuất lại dữ liệu từ ứng dụng ""%1"" và khởi động đồng bộ trong chương trình này.
		|Cũng có thể xóa thông điệp để so sánh. Trong trường hợp này, đồng bộ hóa sẽ làm việc ở chế độ thường.';
		|ru = 'При загрузке сообщения для сопоставления возникла ошибка.
		|Рекомендуется повторно выгрузить данные из приложения ""%1"" и запустить синхронизацию в этой программе.
		|Также, можно удалить сообщение для сопоставления. В этом случае синхронизация будет работать в обычном режиме.';
		|en = 'An error occurred while importing a message for mapping.
		|It is recommended that you export data from application ""%1"" again and start synchronization in this application.
		|You can also delete the message for mapping. In this case, synchronization runs in normal mode.'; fa = 'هنگام ورود اطلاعات پیام برای تطبیق خطایی رخ داد.
		|توصیه می‌شود دوباره از برنامه ""%1"" خروج اطلاعات انجام داده و همگام‌سازی را در این برنامه آغاز کنید.
		|همچنین می‌توانید پیام تطبیق را حذف کنید. در این صورت، همگام‌سازی در حالت عادی اجرا می‌شود.';
		|it = 'Durante lo scaricamento del messaggio per l''abbinamento si è verificato un errore. 
		| Si consiglia di scaricare di nuovo i dati dall''applicazione ""%1"" e avviare la sincronizzazione in questo programma. 
		|Inoltre, è possibile eliminare il messaggio per l''abbinamento. In questo caso la sincronizzazione funzionerà regolarmente.';
		|pl = 'Podczas pobierania wiadomości do pobierania zaistniał błąd.
		|Zaleca się ponownie przesłać dane z aplikacji ""%1"" и i uruchomić synchronizację w tym programie.
		|Również można usunąć wiadomość do usunięcia. W tym przypadku synchronizacja będzie pracować w trybie zwykłym.';
		|tr = 'Eşleşecek bir mesaj yüklenirken bir hata oluştu.
		| Verileri ""%1"" uygulamasından yeniden yüklemeniz ve bu programda senkronizasyonu başlatmanız önerilir. 
		|Ayrıca, eşleştirmek için mesajı silebilirsiniz. Bu durumda, senkronizasyon normal şekilde çalışacaktır.'"),
		PeerInfobaseName);
	
	InitializeScheduleSetupWizard(IsStartedFromAnotherApplication);
	
	If ExportAdditionMode Then
		InitializeExportAdditionAttributes();
	EndIf;
	
	TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(
		Object.InfobaseNode,
		Object.TransportID);

	If Object.TransportID = "SM" And TransportSettings.InternalPublication Then
		ExchangeViaInternalPublication = True;
		CorrespondentDataArea = TransportSettings.CorrespondentDataArea; 
	Else
		ExchangeViaInternalPublication = False;
	EndIf;
	
	AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(Object.InfobaseNode);
	
	UseProgressBar = ExchangeMessagesTransport.TransportParameter(Object.TransportID, "UseProgress");

	Items.GroupWarningWhenSharingViaInternalPublishing.Visible = 
		ExchangeViaInternalPublication And Not MessageReceivedForDataMapping;
	
	FillNavigationTable();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseForm Then
		Return;
	EndIf;

	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject, Cancel, Exit,
		NStr("vi = 'Thoát khỏi trợ giúp?';
			|ru = 'Выйти из помощника?';
			|en = 'Do you want to exit the wizard?'; fa = 'Do you want to exit the wizard?';
			|it = 'Uscire dall''assistente?';
			|pl = 'Wyjść z asystenta?';
			|tr = 'Sihirbazdan çıkmak istiyor musunuz?'"), "ForceCloseForm");
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperation Then
		EndExecutingTimeConsumingOperation(JobID);
	EndIf;
	
	If MessageReceivedForDataMapping And Not MappingCancellation Then
		If (EndDataMapping And Not SkipGettingData)
			Or (DataImportResult = "Warning_ExchangeMessageAlreadyAccepted")
			Or DeleteMessageForMapping Then
			DeleteMessageForDataMapping(Object.InfobaseNode, Object.TransportID);
		EndIf;
	EndIf;
	
	DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessagesDirectoryName, TempDirectoryIDForExchange);
	
	If ValueIsFilled(FormReopeningParameters)
		And FormReopeningParameters.Property("NewDataSynchronizationSetting") Then
		
		NewDataSynchronizationSetting = FormReopeningParameters.NewDataSynchronizationSetting;
		
		FormParameters = New Structure;
		FormParameters.Insert("InfobaseNode", NewDataSynchronizationSetting);
		FormParameters.Insert("AdvancedExportAdditionMode", True);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
		DataExchangeClient.OpenFormAfterCloseCurrentOne(ThisObject,
			"DataProcessor.InteractiveDataExchangeWizard.Form", FormParameters, OpeningParameters);
		
	Else
		Notify("ObjectMappingWizardFormClosed");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// Check whether the additional export item initialization event occurred. 
	If DataExchangeClient.ExportAdditionChoiceProcessing(ValueSelected, ChoiceSource, ExportAddition) Then
		// Event is handled, updating filter details.
		SetExportAdditionFilterDescription();
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ObjectMappingFormClosing" Then
		
		Cancel = False;
		
		UpdateMappingStatisticsDataAtServer(Cancel, Parameter);
		
		If Cancel Then
			ShowMessageBox(, NStr("vi = 'Khi nhận thông tin thống kê đã xảy ra lỗi.';
									|ru = 'При получении информации статистики возникли ошибки.';
									|en = 'Error gathering statistic data.'; fa = 'Error gathering statistic data.';
									|it = 'Si sono verificati errori durante l''acquisizione delle informazioni statistiche.';
									|pl = 'Podczas otrzymania informacji statystycznych wynikły błędy.';
									|tr = 'İstatistik bilgisi alınırken hatalar oluştu.'"));
		Else
			
			ExpandStatisticsTree(Parameter.UniqueKey);
			
			ShowUserNotification(NStr("vi = 'Đã hoàn thành thu thập thông tin';
										|ru = 'Сбор информации завершен';
										|en = 'Information collection is complete'; fa = 'Information collection is complete';
										|it = 'Raccolta di informazioni è completata';
										|pl = 'Zbieranie informacji zostało zakończone';
										|tr = 'Bilgi toplama tamamlandı'"));
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// The page of the Informationstatistics page

&AtClient
Procedure EndDataMappingOnChange(Item)
	
	OnChangeFlagEndDataMapping();
	
EndProcedure

&AtClient
Procedure LoadMessageAfterMappingOnChange(Item)
	
	OnChangeFlagImportMessageAfterMapping();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Page pagesreferences

&AtClient
Procedure ExportAdditionExportVariantOnChange(Item)
	ExportAdditionExportVariantSetVisibility();
EndProcedure

&AtClient
Procedure ExportAdditionNodeScenarioFilterPeriodOnChange(Item)
	ExportAdditionNodeScenarioPeriodChanging();
EndProcedure

&AtClient
Procedure ExportAdditionCommonDocumentsPeriodClearing(Item, StandardProcessing)
	// Forbid period clearing.
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ExportAdditionNodeScenarioFilterPeriodClearing(Item, StandardProcessing)
	// Forbid period clearing.
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStatisticsInformationTree

&AtClient
Procedure StatisticsInformationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenMappingForm(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	MappingCancellation = True;
	Close();
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	// Updating all opened dynamic lists.
	DataExchangeClient.RefreshAllOpenDynamicLists();
	
	Result = New Structure;
	Result.Insert("DataExportResult", DataExportResult);
	Result.Insert("DataImportResult", DataImportResult);
	
	ForceCloseForm = True;
	Close(Result);
	
EndProcedure

&AtClient
Procedure OpenScheduleSettings(Command)
	FormParameters = New Structure("InfobaseNode", Object.InfobaseNode);
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure ContinueSync(Command)
	
	NavigationNumber = NavigationNumber - 1;
	SetNavigationNumber(NavigationNumber + 1);
	
EndProcedure

&AtClient
Procedure EndSyncing(Command)

	CompleteSynchronizationOnServer(); 
	
	ForceCloseForm = True;
	Close();

EndProcedure

&AtServer
Procedure CompleteSynchronizationOnServer()

	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.HasNodeScheduledExchange(
		Object.InfobaseNode, 
		ScenarioUsingInternalPublication,
		IDOfExchangeViaInternalPublication);
			
	CancelQueueAndResumeOnServer();
    
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The page of the Informationstatistics page

&AtClient
Procedure RefreshAllMappingInformation(Command)
	
	CurrentData = Items.StatisticsInformationTree.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentRowKey = CurrentData.Key;
		
	EndIf;
	
	Cancel = False;
	
	RowsKeys = New Array;
	
	GetAllRowKeys(RowsKeys, StatisticsInformationTree.GetItems());
	
	If RowsKeys.Count() > 0 Then
		
		UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys);
		
	EndIf;
	
	If Cancel Then
		ShowMessageBox(, NStr("vi = 'Khi nhận thông tin thống kê đã xảy ra lỗi.';
								|ru = 'При получении информации статистики возникли ошибки.';
								|en = 'Error gathering statistic data.'; fa = 'Error gathering statistic data.';
								|it = 'Si sono verificati errori durante l''acquisizione delle informazioni statistiche.';
								|pl = 'Podczas otrzymania informacji statystycznych wynikły błędy.';
								|tr = 'İstatistik bilgisi alınırken hatalar oluştu.'"));
	Else
		
		ExpandStatisticsTree(CurrentRowKey);
		
		ShowUserNotification(NStr("vi = 'Đã hoàn thành thu thập thông tin';
									|ru = 'Сбор информации завершен';
									|en = 'Information collection is complete'; fa = 'Information collection is complete';
									|it = 'Raccolta di informazioni è completata';
									|pl = 'Zbieranie informacji zostało zakończone';
									|tr = 'Bilgi toplama tamamlandı'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure RunDataImportForRow(Command)
	
	Cancel = False;
	
	SelectedRows = Items.StatisticsInformationTree.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		NString = NStr("vi = 'Hãy chọn tên bảng tại trường thông tin thống kê.';
						|ru = 'Выберите имя таблицы в поле статистической информации.';
						|en = 'Select a table name in the statistics field.'; fa = 'Select a table name in the statistics field.';
						|it = 'Selezionare il nome della tabella nel campo delle informazioni statistiche.';
						|pl = 'Wybierz nazwę tabeli w polu informacji statystycznych.';
						|tr = 'İstatistik bilgi alanında bir tablo adı seçin.'");
		CommonClient.MessageToUser(NString,,"StatisticsInformationTree",, Cancel);
		Return;
	EndIf;
	
	HasUnmappedObjects = False;
	For Each RowID In SelectedRows Do
		TreeRow = StatisticsInformationTree.FindByID(RowID);
		
		If IsBlankString(TreeRow.Key) Then
			Continue;
		EndIf;
		
		If TreeRow.UnmappedObjectsCount <> 0 Then
			HasUnmappedObjects = True;
			Break;
		EndIf;
	EndDo;
	
	If HasUnmappedObjects Then
		NString = NStr("vi = 'Có đối tượng chưa được so sánh.
		                     |Khi kết nhập dữ liệu sẽ tạo ra các bản trùng lặp đối tượng chưa so sánh. Tiếp tục?';
		                     |ru = 'Имеются несопоставленные объекты.
		                     |При загрузке данных будут созданы дубли несопоставленных объектов. Продолжить?';
		                     |en = 'Unmapped objects are found.
		                     |When you import the data, duplicates of these objects will be created. Do you want to continue?'; fa = 'Unmapped objects are found.
		                     |When you import the data, duplicates of these objects will be created. Do you want to continue?';
		                     |it = 'Esistono oggetti non associati.
		                     |Durante il download dei dati, verranno creati duplicati di oggetti non associati. Continuare?';
		                     |pl = 'Są niedopasowane obiekty. 
		                     |Podczas pobierania danych będą utworzone duplikaty niedopasowanych obiektów. Kontynuować?';
		                     |tr = 'Eşsiz nesneler vardır.
		                     | Veri içe aktarılırken eşleştirilmemiş nesne çiftleri oluşturulacak. Devam edilsin mi?'");
		
		Notification = New CallbackDescription("ExecuteDataImportForRowQuestionUnmapped", ThisObject, New Structure);
		Notification.AdditionalParameters.Insert("SelectedRows", SelectedRows);
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	RunDataImportForRowContinued(SelectedRows);
EndProcedure

&AtClient
Procedure OpenMappingForm(Command)
	
	CurrentData = Items.StatisticsInformationTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(CurrentData.Key) Then
		Return;
	EndIf;
	
	If Not CurrentData.UsePreview Then
		ShowMessageBox(, NStr("vi = 'Đối với kiểu dữ liệu này, không thể thực hiện so sánh đối tượng.';
								|ru = 'Для типа данных нельзя выполнить сопоставление объектов.';
								|en = 'Object mapping cannot be performed for the data type.'; fa = 'Object mapping cannot be performed for the data type.';
								|it = 'Impossibile effettuare l''associazione degli oggetti per il tipo dei dati.';
								|pl = 'Dla rodzaju danych nie można wykonać dopasowanie obiektów.';
								|tr = 'Veri türü için nesneler karşılaştırılamaz.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DestinationTableName",            CurrentData.DestinationTableName);
	FormParameters.Insert("SourceTableObjectTypeName", CurrentData.ObjectTypeString);
	FormParameters.Insert("DestinationTableFields",           CurrentData.TableFields);
	FormParameters.Insert("DestinationTableSearchFields",     CurrentData.SearchFields);
	FormParameters.Insert("SourceTypeString",            CurrentData.SourceTypeString);
	FormParameters.Insert("DestinationTypeString",            CurrentData.DestinationTypeString);
	FormParameters.Insert("IsObjectDeletion",             CurrentData.IsObjectDeletion);
	FormParameters.Insert("DataImportedSuccessfully",         CurrentData.DataImportedSuccessfully);
	FormParameters.Insert("Key",                           CurrentData.Key);
	FormParameters.Insert("Synonym",                        CurrentData.Synonym);
	
	FormParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	FormParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	
	OpenForm("DataProcessor.InfobasesObjectsMapping.Form", FormParameters, ThisObject);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Page of the end pagesreferences

&AtClient
Procedure GoToDataImportEventLog(Command)
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
	
EndProcedure

&AtClient
Procedure GoToDataExportEventLog(Command)
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataExport");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Page pagesreferences

&AtClient
Procedure ExportAdditionGeneralDocumentsFilter(Command)
	DataExchangeClient.OpenExportAdditionFormAllDocuments(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionDetailedFilter(Command)
	DataExchangeClient.OpenExportAdditionFormDetailedFilter(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionFilterByNodeScenario(Command)
	DataExchangeClient.OpenExportAdditionFormNodeScenario(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionExportComposition(Command)
	DataExchangeClient.OpenExportAdditionFormDataComposition(ExportAddition, ThisObject);
EndProcedure

&AtClient
Procedure ExportAdditionClearGeneralFilter(Command)
	
	TitleText = NStr("vi = 'Xác nhận';
					|ru = 'Подтверждение';
					|en = 'Confirm operation'; fa = 'Confirm operation';
					|it = 'Conferma';
					|pl = 'Potwierdzenie';
					|tr = 'Parolayı doğrula'");
	QueryText   = NStr("vi = 'Xóa bộ lọc chung?';
						|ru = 'Очистить общий отбор?';
						|en = 'Do you want to clear the common filter?'; fa = 'Do you want to clear the common filter?';
						|it = 'Cancellare il contenuto della selezione generale?';
						|pl = 'Oczyścić wspólny dobór?';
						|tr = 'Ortak filtre temizlensin mi?'");
	CallbackDescription = New CallbackDescription("ExportAdditionClearGeneralFilterCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,,,TitleText);
	
EndProcedure

&AtClient
Procedure ExportAdditionClearDetailedFilter(Command)
	TitleText = NStr("vi = 'Xác nhận';
					|ru = 'Подтверждение';
					|en = 'Confirm operation'; fa = 'Confirm operation';
					|it = 'Conferma';
					|pl = 'Potwierdzenie';
					|tr = 'Parolayı doğrula'");
	QueryText   = NStr("vi = 'Xóa bộ lọc chi tiết?';
						|ru = 'Очистить детальный отбор?';
						|en = 'Do you want to clear the detailed filter?'; fa = 'Do you want to clear the detailed filter?';
						|it = 'Cancellare il contenuto della selezione dettagliata?';
						|pl = 'Oczyścić szczegółowy dobór?';
						|tr = 'Ayrıntılı filtre temizlensin mi?'");
	CallbackDescription = New CallbackDescription("ExportAdditionClearDetailedFilterCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,,,TitleText);
EndProcedure

&AtClient
Procedure ExportAdditionFiltersHistory(Command)
	// Filling a menu list with all saved settings options.
	VariantList = ExportAdditionServerSettingsHistory();
	
	// Adding the option for saving the current settings.
	Text = NStr("vi = 'Lưu lại tùy chỉnh hiện tại...';
				|ru = 'Сохранить текущую настройку...';
				|en = 'Save current setting…'; fa = 'Save current setting…';
				|it = 'Salvare la configurazione corrente...';
				|pl = 'Zapisz bieżące ustawienie ...';
				|tr = 'Mevcut ayarlar kaydediliyor...'");
	VariantList.Add(1, Text, , PictureLib.SaveReportSettings);
	
	CallbackDescription = New CallbackDescription("ExportAdditionFilterHistoryMenuSelection", ThisObject);
	ShowChooseFromMenu(CallbackDescription, VariantList, Items.ExportAdditionFiltersHistory);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 1C-SUPPLIED SECTION
////////////////////////////////////////////////////////////////////////////////
//

#Region PartToSupply

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And Item.CommandName = CommandName Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure ExecuteMoveNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		
		NavigationNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	Items.NavigationPanel.CurrentPage.Enabled = Not (IsMoveNext And NavigationRowCurrent.TimeConsumingOperation);
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			NavigationRow = NavigationRows[0];
		
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(NavigationNumber - 1);
					
					Return;
					
				EndIf;
				
			EndIf;
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(NavigationNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(NavigationNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			If VersionDifferenceErrorOnGetData <> Undefined
				And VersionDifferenceErrorOnGetData.HasError Then
				
				ProcessVersionDifferenceError();
				Return;
				
			EndIf;
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NavigationTableNewRow(
									MainPageName,
									NavigationPageName,
									OnOpenHandlerName = "",
									OnNavigationToNextPageHandlerName = "")
									
	NewRow = NavigationTable.Add();
	
	NewRow.NavigationNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	NewRow.OnNavigationToNextPageHandlerName = OnNavigationToNextPageHandlerName;
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = False;
	NewRow.TimeConsumingOperationHandlerName = "";
	
EndProcedure

&AtServer
Procedure NavigationTableNewRowTimeConsumingOperation(
									MainPageName,
									NavigationPageName,
									TimeConsumingOperation = False,
									TimeConsumingOperationHandlerName = "",
									OnOpenHandlerName = "")
	
	NewRow = NavigationTable.Add();
	
	NewRow.NavigationNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	NewRow.OnNavigationToNextPageHandlerName = "";
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = TimeConsumingOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// OVERRIDABLE SECTION
////////////////////////////////////////////////////////////////////////////////
//

#Region OverridablePart

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS SECTION

#Region ProceduresAndFuctionsOfProcessing

#Region ProceduresAndFunctionsClient

&AtClient
Procedure InitializeDataProcessorVariables()
	
	// Initialize data processor variables.
	ProgressPercent                   = 0;
	FileID                  = "";
	ProgressAdditionalInformation             = "";
	TempStorageAddress            = "";
	ErrorMessage                   = "";
	OperationID               = "";
	TimeConsumingOperation                  = False;
	TimeConsumingOperationCompleted         = True;
	TimeConsumingOperationCompletedWithError = False;
	JobID                = Undefined;
	
EndProcedure

&AtClient
Procedure ExportAdditionFiltersHistoryCompletion(Response, SettingPresentation) Export
	
	If Response = DialogReturnCode.Yes Then
		ExportAdditionSetSettingsServer(SettingPresentation);
		ExportAdditionExportVariantSetVisibility();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportAdditionClearGeneralFilterCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		ExportAdditionClearGeneralFilterServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportAdditionClearDetailedFilterCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		ExportAdditionClearDetailedFilterServer();
	EndIf;
EndProcedure

&AtClient
Procedure ExportAdditionFilterHistoryMenuSelection(Val SelectedElement, Val AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
		
	SettingPresentation = SelectedElement.Value;
	If TypeOf(SettingPresentation)=Type("String") Then
		// An option is selected, which is name of the setting saved earlier.
		
		TitleText = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khôi phục tùy chỉnh ""%1""?';
			|ru = 'Восстановить настройки ""%1""?';
			|en = 'Do you want to restore ""%1"" settings?'; fa = 'Do you want to restore ""%1"" settings?';
			|it = 'Ripristinare le configurazioni ""%1""?';
			|pl = 'Przywróć ustawienia ""%1""?';
			|tr = '""%1"" ayarları geri yüklensin mi?'"), SettingPresentation);
		
		CallbackDescription = New CallbackDescription("ExportAdditionFiltersHistoryCompletion", ThisObject, SettingPresentation);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,,,TitleText);
		
	ElsIf SettingPresentation=1 Then
		// A save option is selected, opening the form of all settings.
		DataExchangeClient.OpenExportAdditionFormSaveSettings(ExportAddition, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataImportForRowQuestionUnmapped(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RunDataImportForRowContinued(AdditionalParameters.SelectedRows);
EndProcedure

&AtClient
Procedure RunDataImportForRowContinued(Val SelectedRows) 

	RowsKeys = GetSelectedRowKeys(SelectedRows);
	If RowsKeys.Count() = 0 Then
		Return;
	EndIf;
	
	Cancel = False;
	UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys, True);
	
	If Cancel Then
		NString = NStr("vi = 'Khi kết nhập dữ liệu, đã xảy ra lỗi.
		                     |Chuyển đến nhật ký sự kiện?';
		                     |ru = 'При загрузке данных возникли ошибки.
		                     |Перейти в журнал регистрации?';
		                     |en = 'Errors occurred during data import.
		                     |Do you want to view the event log?'; fa = 'Errors occurred during data import.
		                     |Do you want to view the event log?';
		                     |it = 'Si sono verificati degli errori durante il download dei dati.
		                     |Passare al registro?';
		                     |pl = 'Podczas pobierania danych wystąpiły błędy. 
		                     |Przejść do dziennika rejestracji?';
		                     |tr = 'Veriler içe aktarılırken hatalar oluştu.
		                     |Olay günlüğünü açmak ister misiniz?'");
		
		CallbackDescription = New CallbackDescription("GoToEventLog", ThisObject);
		ShowQueryBox(CallbackDescription, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
		
	ExpandStatisticsTree(RowsKeys[RowsKeys.UBound()]);
	ShowUserNotification(NStr("vi = 'Đã hoàn thành kết nhập dữ liệu.';
								|ru = 'Загрузка данных завершена.';
								|en = 'Data import completed.'; fa = 'Data import completed.';
								|it = 'Download dei dati è completato.';
								|pl = 'Zakończono pobieranie danych';
								|tr = 'Veri içe aktarımı tamamlandı.'"));
EndProcedure

&AtClient
Procedure GoToEventLog(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessVersionDifferenceError()
	
	Items.PanelMain.CurrentPage             = Items.VersionsDifferenceErrorPage;
	Items.NavigationPanel.CurrentPage            = Items.NavigationPageVersionsDifferenceError;
	Items.ContinueSync.DefaultButton  = True;
	Items.DecorationVersionsDifferenceError.Title = VersionDifferenceErrorOnGetData.ErrorText;
	
	VersionDifferenceErrorOnGetData = Undefined;
	
	CheckVersionDifference = False;
	
EndProcedure

&AtClient
Procedure OnChangeFlagEndDataMapping()
	
	LoadMessageAfterMapping = EndDataMapping;
	
	Items.LoadMessageAfterMapping.Enabled = EndDataMapping;
	
	UpdateAvailabilityOfStatisticsInformationMoveCommand();
	UpdateTooltipTitleOfStatisticsInformationMove();
	
EndProcedure

&AtClient
Procedure OnChangeFlagImportMessageAfterMapping()
	
	UpdateAvailabilityOfStatisticsInformationMoveCommand();
	UpdateTooltipTitleOfStatisticsInformationMove();
	
EndProcedure

&AtClient
Procedure UpdateTooltipTitleOfStatisticsInformationMove()
	
	If MessageReceivedForDataMapping Then
		If EndDataMapping Then
			If LoadMessageAfterMapping Then
				Items.StatisticsDataNavigationTooltipDecoration.Title =
					NStr("vi = 'Hãy nhấn nút ""Tiếp theo"" để hoàn thành so sánh dữ liệu và kết nhập thông điệp trao đổi.';
						|ru = 'Нажмите кнопку ""Далее"" для завершения сопоставления данных и загрузки сообщения обмена.';
						|en = 'Click Next to confirm the mapping and import the exchange message.'; fa = 'Click Next to confirm the mapping and import the exchange message.';
						|it = 'Fare clic sul pulsante ""Avanti"" per completare l''associazione dati e scaricare il messaggio di scambio.';
						|pl = 'Kliknij przycisk ""Dalej"", aby zakończyć dopasowanie danych i pobieranie wiadomości wymiany.';
						|tr = 'Veri eşlemesini tamamlamak ve veri alışverişi mesajını yüklemek için ""İleri"" düğmesini tıklayın.'");
			Else
				Items.StatisticsDataNavigationTooltipDecoration.Title =
					NStr("vi = 'Hãy nhấn nút ""Lưu lại và đóng"" để hoàn thành so sánh dữ liệu và thoát khỏi trợ giúp.';
						|ru = 'Нажмите кнопку ""Сохранить и закрыть"" для завершения сопоставления данных и выхода из помощника.';
						|en = 'Click ""Save and close"" to confirm the mapping and exit the wizard.'; fa = 'Click ""Save and close"" to confirm the mapping and exit the wizard.';
						|it = 'Fare clic sul pulsante ""Salvare e chiudere"" per completare l''associazione dati e uscire dall''assistente.';
						|pl = 'Kliknij przycisk ""Zapisz i zamknij"", aby zakończyć dopasowanie danych i wyjścia z asystenta.';
						|tr = 'Veri eşleştirmesinin tamamlanması ve sihirbazdan çıkış için ""Sakla ve kapat"" düğmesini tıklayın.'");
			EndIf;
		Else
			Items.StatisticsDataNavigationTooltipDecoration.Title =
				NStr("vi = 'Hãy nhấn nút ""Lưu lại và đóng"" để lưu lại kết quả so sánh và thoát khỏi trợ giúp.
				|Trong lần khởi động tiếp theo của trợ giúp, có thể sẽ tiếp tục quá trình so sánh dữ liệu.';
				|ru = 'Нажмите кнопку ""Сохранить и закрыть"" для сохранения результатов сопоставления и выхода из помощника.
				|При следующем запуске помощника можно будет продолжить сопоставление данных.';
				|en = 'Click ""Save and close"" to confirm the mapping and exit the wizard.
				|You can continue editing the mapping next time you start the wizard.'; fa = 'Click ""Save and close"" to confirm the mapping and exit the wizard.
				|You can continue editing the mapping next time you start the wizard.';
				|it = 'Fare clic sul pulsante ""Salvare e chiudere"" per completare l''associazione dei dati e uscire dall''assistente.
				|Al prossimo avvio dell''assistente sarà possibile continuare l''associazione dei dati.';
				|pl = 'Kliknij przycisk ""Zapisz i zamknij"", aby zapisać wyniki dopasowania i wyjścia z asystenta.
				|Przy następnym uruchomieniu asystenta będzie można kontynuować dopasowanie danych.';
				|tr = 'Veri eşleştirmesinin tamamlanması ve sihirbazdan çıkış için ""Sakla ve kapat"" düğmesini tıklayın.
				|Sihirbazın bir sonraki çalıştırılmasında verilerin eşleşmesine devam edilebilir.'");
		EndIf;
	Else
		Items.StatisticsDataNavigationTooltipDecoration.Title =
			NStr("vi = 'Hãy nhấn nút ""Tiếp theo"" để đồng bộ dữ liệu.';
				|ru = 'Нажмите кнопку ""Далее"" для синхронизации данных.';
				|en = 'Click Next to synchronize data.'; fa = 'برای همگام‌سازی داده روی بعدی کلیک کنید.';
				|it = 'Fare clic sul pulsante ""Avanti"" per sincronizzare i dati.';
				|pl = 'Naciśnij przycisk ""Dalej"" w celu synchronizacji danych.';
				|tr = 'Verileri senkronize etmek için İleri''ye tıklayın.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfStatisticsInformationMoveCommand()
	
	Items.DoneCommand.Enabled = Not EndDataMapping Or Not LoadMessageAfterMapping;
	Items.DoneCommand.DefaultButton = EndDataMapping;
	
	Items.StatisticsInformationNextCommand.Enabled = EndDataMapping And LoadMessageAfterMapping;
	Items.StatisticsInformationNextCommand.DefaultButton = EndDataMapping And LoadMessageAfterMapping;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsServer

&AtServer
Procedure UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys, RunDataImport = False)
	
	RowIndexes = GetStatisticsTableRowIndexes(RowsKeys);
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	If RunDataImport Then
		DataProcessorObject.RunDataImport(Cancel, RowIndexes);
	EndIf;
	
	// Getting mapping statistic data.
	DataProcessorObject.GetObjectMappingByRowStats(Cancel, RowIndexes);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	StatisticsInformation(DataProcessorObject.StatisticsTable());
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	
	AllDataMapped   = ModuleInteractiveExchangeWizard.AllDataMapped(DataProcessorObject.StatisticsTable());
	HasUnmappedMasterData = Not AllDataMapped And ModuleInteractiveExchangeWizard.HasUnmappedMasterData(DataProcessorObject.StatisticsTable());
	
	SetAdditionalInfoGroupVisible();
	
EndProcedure

&AtServer
Procedure UpdateMappingStatisticsDataAtServer(Cancel, NotificationParameters)
	
	TableRows = Object.StatisticsInformation.FindRows(New Structure("Key", NotificationParameters.UniqueKey));
	
	If TableRows.Count() > 0 Then
		FillPropertyValues(TableRows[0], NotificationParameters, "DataImportedSuccessfully");
		
		RowsKeys = New Array;
		RowsKeys.Add(NotificationParameters.UniqueKey);
		
		UpdateMappingByRowDetailsAtServer(Cancel, RowsKeys);
	EndIf;
	
EndProcedure

&AtServer
Procedure StatisticsInformation(StatisticsInformation)
	
	TreeItemsCollection = StatisticsInformationTree.GetItems();
	TreeItemsCollection.Clear();
	
	Common.FillFormDataTreeItemCollection(TreeItemsCollection,
		DataExchangeServer.StatisticsInformation(StatisticsInformation));
	
EndProcedure

&AtServer
Procedure SetAdditionalInfoGroupVisible()
	
	Items.DataMappingStatusPages.CurrentPage = ?(AllDataMapped,
		Items.MappingStatusAllDataMapped,
		Items.MappingStatusUnmappedDataDetected);
	
EndProcedure

&AtServer
Procedure InitializeExchangeMessagesTransportSettings()
	
	TransportID = ExchangeMessagesTransport.DefaultTransport(Object.InfobaseNode);
	
	SkipTransportPage = True;
	
	If Not ValueIsFilled(Object.TransportID) Then
		Object.TransportID = TransportID;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeScheduleSetupWizard(IsStartedFromAnotherApplication)
	
	OpenDataExchangeScenarioCreationWizard = DataExchangeServer.HasRightsToAdministerExchanges();
	
	If IsStartedFromAnotherApplication Then
		OpenDataExchangeScenarioCreationWizard = False;
	ElsIf Parameters.Property("ScheduleSetup") Then
		OpenDataExchangeScenarioCreationWizard = Parameters.ScheduleSetup;
	EndIf;
	
	Items.ScheduleSettingsHelpText.Visible = OpenDataExchangeScenarioCreationWizard;
	
EndProcedure

&AtServer
Function GetStatisticsTableRowIndexes(RowsKeys)
	
	RowIndexes = New Array;
	
	For Each Var_Key In RowsKeys Do
		
		TableRows = Object.StatisticsInformation.FindRows(New Structure("Key", Var_Key));
		
		RowIndex = Object.StatisticsInformation.IndexOf(TableRows[0]);
		
		RowIndexes.Add(RowIndex);
		
	EndDo;
	
	Return RowIndexes;
	
EndFunction

&AtServer
Procedure CheckWhetherTransferToNewExchangeIsRequired()
	
	ArrayOfMessages = GetUserMessages(True);
	
	If ArrayOfMessages = Undefined Then
		Return;
	EndIf;
	
	Count = ArrayOfMessages.Count();
	If Count = 0 Then
		Return;
	EndIf;
	
	Message      = ArrayOfMessages[Count-1];
	MessageText = Message.Text;
	
	// A subsystem ID is deleted from the message if necessary.
	If StrStartsWith(MessageText, "{MigrationToNewExchangeDone}") Then
		
		MessageData = Common.ValueFromXMLString(MessageText);
		
		If MessageData <> Undefined
			And TypeOf(MessageData) = Type("Structure") Then
			
			ExchangePlanName                    = MessageData.ExchangePlanNameToMigrateToNewExchange;
			ExchangePlanNodeCode                = MessageData.Code;
			NewDataSynchronizationSetting = ExchangePlans[ExchangePlanName].FindByCode(ExchangePlanNodeCode);
			
			BackgroundJobExecutionResult.AdditionalResultData.Insert("FormReopeningParameters",
				New Structure("NewDataSynchronizationSetting", NewDataSynchronizationSetting));
				
			BackgroundJobExecutionResult.AdditionalResultData.Insert("ForceCloseForm", True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareExportAdditionStructure(StructureAddition)
	
	StructureAddition = New Structure;
	StructureAddition.Insert("ExportOption", ExportAddition.ExportOption);
	StructureAddition.Insert("AllDocumentsFilterPeriod", ExportAddition.AllDocumentsFilterPeriod);
	
	StructureAddition.Insert("AllDocumentsComposer", Undefined);
	If Not IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		AllDocumentsComposer = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
		
		StructureAddition.AllDocumentsComposer = AllDocumentsComposer;
	EndIf;
	
	StructureAddition.Insert("NodeScenarioFilterPeriod", ExportAddition.NodeScenarioFilterPeriod);
	StructureAddition.Insert("NodeScenarioFilterPresentation", ExportAddition.NodeScenarioFilterPresentation);
	StructureAddition.Insert("AdditionScenarioParameters", ExportAddition.AdditionScenarioParameters);
	StructureAddition.Insert("CurrentSettingsItemPresentation", ExportAddition.CurrentSettingsItemPresentation);
	StructureAddition.Insert("InfobaseNode", ExportAddition.InfobaseNode);
	
	StructureAddition.Insert("AllDocumentsSettingFilterComposer", ExportAddition.AllDocumentsFilterComposer.GetSettings());
	
	StructureAddition.Insert("AdditionalNodeScenarioRegistration", ExportAddition.AdditionalNodeScenarioRegistration.Unload());
	StructureAddition.Insert("AdditionalRegistration", ExportAddition.AdditionalRegistration.Unload());
	
EndProcedure

#Region ExportAdditionOperations

&AtServer
Procedure InitializeExportAdditionAttributes()
	
	// Getting settings as a structure, settings will be saved implicitly to the form temporary storage.
	ExportAdditionSettings = DataExchangeServer.InteractiveExportChange(
		Object.InfobaseNode, UUID, ExportAdditionExtendedMode);
	
	// Configure the form.
	// Convert it into the form attribute of the type "DataProcessorObject" (to access the form seamlessly).
	DataExchangeServer.InteractiveExportChangeAttributeBySettings(ThisObject, ExportAdditionSettings, "ExportAddition");
	
	AdditionScenarioParameters = ExportAddition.AdditionScenarioParameters;
	
	// Configuring interface according to the specified scenario.
	
	// Special cases.
	StandardVariantsProhibited = Not AdditionScenarioParameters.OptionDoNotAdd.Use
		And Not AdditionScenarioParameters.AllDocumentsOption.Use
		And Not AdditionScenarioParameters.ArbitraryFilterOption.Use;
		
	If StandardVariantsProhibited Then
		If AdditionScenarioParameters.AdditionalOption.Use Then
			// A single node scenario option is available.
			Items.ExportAdditionNodeAsStringExportOption.Visible = True;
			Items.ExportAdditionNodeExportOption.Visible        = False;
			Items.CustomGroupIndentDecoration.Visible           = False;
			ExportAddition.ExportOption = 3;
		Else
			// Nothing is found. Setting the flag showing that the page is skipped and exiting.
			ExportAddition.ExportOption = -1;
			Items.ExportAdditionOptions.Visible = False;
			Return;
		EndIf;
	EndIf;
	
	// Setting typical input fields.
	Items.StandardAdditionOptionNone.Visible = AdditionScenarioParameters.OptionDoNotAdd.Use;
	If Not IsBlankString(AdditionScenarioParameters.OptionDoNotAdd.Title) Then
		Items.ExportAdditionExportOption0.ChoiceList[0].Presentation = AdditionScenarioParameters.OptionDoNotAdd.Title;
	EndIf;
	Items.StandardAdditionOptionNoneNote.Title = AdditionScenarioParameters.OptionDoNotAdd.Explanation;
	If IsBlankString(Items.StandardAdditionOptionNoneNote.Title) Then
		Items.StandardAdditionOptionNoneNote.Visible = False;
	EndIf;
	
	Items.StandardAdditionOptionDocuments.Visible = AdditionScenarioParameters.AllDocumentsOption.Use;
	If Not IsBlankString(AdditionScenarioParameters.AllDocumentsOption.Title) Then
		Items.ExportAdditionExportOption1.ChoiceList[0].Presentation = AdditionScenarioParameters.AllDocumentsOption.Title;
	EndIf;
	Items.StandardAdditionOptionDocumentsNote.Title = AdditionScenarioParameters.AllDocumentsOption.Explanation;
	If IsBlankString(Items.StandardAdditionOptionDocumentsNote.Title) Then
		Items.StandardAdditionOptionDocumentsNote.Visible = False;
	EndIf;
	
	Items.StandardAdditionOptionCustom.Visible = AdditionScenarioParameters.ArbitraryFilterOption.Use;
	If Not IsBlankString(AdditionScenarioParameters.ArbitraryFilterOption.Title) Then
		Items.ExportAdditionExportOption2.ChoiceList[0].Presentation = AdditionScenarioParameters.ArbitraryFilterOption.Title;
	EndIf;
	Items.StandardAdditionOptionCustomNote.Title = AdditionScenarioParameters.ArbitraryFilterOption.Explanation;
	If IsBlankString(Items.StandardAdditionOptionCustomNote.Title) Then
		Items.StandardAdditionOptionCustomNote.Visible = False;
	EndIf;
	
	Items.CustomAdditionOption.Visible           = AdditionScenarioParameters.AdditionalOption.Use;
	Items.ExportPeriodNodeScenarioGroup.Visible         = AdditionScenarioParameters.AdditionalOption.UseFilterPeriod;
	Items.ExportAdditionFilterByNodeScenario.Visible    = Not IsBlankString(AdditionScenarioParameters.AdditionalOption.FilterFormName);
	
	Items.ExportAdditionNodeExportOption.ChoiceList[0].Presentation = AdditionScenarioParameters.AdditionalOption.Title;
	Items.ExportAdditionNodeAsStringExportOption.Title              = AdditionScenarioParameters.AdditionalOption.Title;
	
	Items.CustomAdditionOptionNote.Title = AdditionScenarioParameters.AdditionalOption.Explanation;
	If IsBlankString(Items.CustomAdditionOptionNote.Title) Then
		Items.CustomAdditionOptionNote.Visible = False;
	EndIf;
	
	// Command titles.
	If Not IsBlankString(AdditionScenarioParameters.AdditionalOption.FormCommandTitle) Then
		Items.ExportAdditionFilterByNodeScenario.Title = AdditionScenarioParameters.AdditionalOption.FormCommandTitle;
	EndIf;
	
	// Sorting visible items.
	AdditionGroupOrder = New ValueList;
	If Items.StandardAdditionOptionNone.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionNone, 
			Format(AdditionScenarioParameters.OptionDoNotAdd.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.StandardAdditionOptionDocuments.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionDocuments, 
			Format(AdditionScenarioParameters.AllDocumentsOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.StandardAdditionOptionCustom.Visible Then
		AdditionGroupOrder.Add(Items.StandardAdditionOptionCustom, 
			Format(AdditionScenarioParameters.ArbitraryFilterOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	If Items.CustomAdditionOption.Visible Then
		AdditionGroupOrder.Add(Items.CustomAdditionOption, 
			Format(AdditionScenarioParameters.AdditionalOption.Order, "ND=10; NZ=; NLZ=; NG="));
	EndIf;
	AdditionGroupOrder.SortByPresentation();
	For Each AdditionGroupItem In AdditionGroupOrder Do
		Items.Move(AdditionGroupItem.Value, Items.ExportAdditionOptions);
	EndDo;
	
	// Editing settings is only allowed if the appropriate rights are granted.
	HasRightsToSetup = AccessRight("SaveUserData", Metadata);
	Items.StandardSettingsOptionsImportGroup.Visible = HasRightsToSetup;
	If HasRightsToSetup Then
		// Restore predefined settings.
		SetFirstItem = Not ExportAdditionSetSettingsServer(DataExchangeServer.ExportAdditionSettingsAutoSavingName());
		ExportAddition.CurrentSettingsItemPresentation = "";
	Else
		SetFirstItem = True;
	EndIf;
		
	SetFirstItem = SetFirstItem
		Or ExportAddition.ExportOption<0 
		Or ( (ExportAddition.ExportOption=0) And (Not AdditionScenarioParameters.OptionDoNotAdd.Use) )
		Or ( (ExportAddition.ExportOption=1) And (Not AdditionScenarioParameters.AllDocumentsOption.Use) )
		Or ( (ExportAddition.ExportOption=2) And (Not AdditionScenarioParameters.ArbitraryFilterOption.Use) )
		Or ( (ExportAddition.ExportOption=3) And (Not AdditionScenarioParameters.AdditionalOption.Use) );
	
	If SetFirstItem Then
		For Each AdditionGroupItem In AdditionGroupOrder[0].Value.ChildItems Do
			If TypeOf(AdditionGroupItem)=Type("FormField") And AdditionGroupItem.Type = FormFieldType.RadioButtonField Then
				ExportAddition.ExportOption = AdditionGroupItem.ChoiceList[0].Value;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	// Initial view, same as ExportAdditionExportVariantSetVisibility client procedure.
	Items.AllDocumentsFilterGroup.Enabled  = ExportAddition.ExportOption=1;
	Items.DetailedFilterGroup.Enabled     = ExportAddition.ExportOption=2;
	Items.CustomFilterGroup.Enabled = ExportAddition.ExportOption=3;
	
	// Description of standard initial filters.
	SetExportAdditionFilterDescription();
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	TitleTemplate1 = NStr("vi = 'Trao đổi dữ liệu với ""%1""';
							|ru = 'Обмен данными с ""%1""';
							|en = 'Exchange data with %1'; fa = 'Exchange data with %1';
							|it = 'Scambio dei dati con ""%1""';
							|pl = 'Wymiana danych z ""%1""';
							|tr = '""%1"" ile veri alışverişi'");
	
	If MessageReceivedForDataMapping Then
		TitleTemplate1 = NStr("vi = 'So sánh dữ liệu ""%1""';
								|ru = 'Сопоставление данных ""%1""';
								|en = 'Map %1 data'; fa = 'Map %1 data';
								|it = 'Associazione dei dati ""%1""';
								|pl = 'Dopasowanie danych ""%1""';
								|tr = '""%1"" verinin eşleşmesi.'");
	ElsIf GetData And SendData Then
		TitleTemplate1 = NStr("vi = 'Đồng bộ dữ liệu với ""%1""';
								|ru = 'Синхронизация данных с ""%1""';
								|en = 'Synchronize data with %1'; fa = 'همگام‌سازی داده با %1';
								|it = 'Sincronizzazione dati con ""%1""';
								|pl = 'Synchronizacja danych z ""%1""';
								|tr = '%1 ile veri senkronizasyonu'");
	ElsIf SendData Then
		TitleTemplate1 = NStr("vi = 'Gửi dữ liệu đối với ""%1""';
								|ru = 'Отправка данных для ""%1""';
								|en = 'Send data to %1'; fa = 'Send data to %1';
								|it = 'Invio dei dati per ""%1""';
								|pl = 'Wysyłanie danych dla ""%1""';
								|tr = '""%1"" için veri gönderiliyor'");
	ElsIf GetData Then
		TitleTemplate1 = NStr("vi = 'Nhận dữ liệu từ ""%1""';
								|ru = 'Получение данных от ""%1""';
								|en = 'Receive data from %1'; fa = 'Receive data from %1';
								|it = 'Ricevimento dei dati da ""%1""';
								|pl = 'Uzyskiwanie danych od ""%1""';
								|tr = '""%1"" ''dan veri alınıyor'");
	EndIf;
		
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		TitleTemplate1, PeerInfobaseName);
	
EndProcedure

&AtClient
Procedure ExportAdditionExportVariantSetVisibility()
	Items.AllDocumentsFilterGroup.Enabled  = ExportAddition.ExportOption=1;
	Items.DetailedFilterGroup.Enabled     = ExportAddition.ExportOption=2;
	Items.CustomFilterGroup.Enabled = ExportAddition.ExportOption=3;
EndProcedure

&AtServer
Procedure ExportAdditionNodeScenarioPeriodChanging()
	DataExchangeServer.InteractiveExportChangeSetNodeScenarioPeriod(ExportAddition);
EndProcedure

&AtServer
Procedure ExportAdditionClearGeneralFilterServer()
	DataExchangeServer.InteractiveExportChangeClearGeneralFilter(ExportAddition);
	SetGeneralFilterAdditionDescription();
EndProcedure

&AtServer
Procedure ExportAdditionClearDetailedFilterServer()
	DataExchangeServer.InteractiveExportChangeDetailsClearing(ExportAddition);
	SetAdditionDetailDescription();
EndProcedure

&AtServer
Procedure SetExportAdditionFilterDescription()
	SetGeneralFilterAdditionDescription();
	SetAdditionDetailDescription();
EndProcedure

&AtServer
Procedure SetGeneralFilterAdditionDescription()
	
	Text = DataExchangeServer.InteractiveExportChangeGeneralFilterAdditionDetails(ExportAddition);
	NoFilter2 = IsBlankString(Text);
	If NoFilter2 Then
		Text = NStr("vi = 'Tất cả chứng từ';
					|ru = 'Все документы';
					|en = 'All documents'; fa = 'همه اسناد';
					|it = 'Tutti i documenti';
					|pl = 'Wszystkie dokumenty';
					|tr = 'Tüm belgeler'");
	EndIf;
	
	Items.ExportAdditionGeneralDocumentsFilter.Title = Text;
	Items.ExportAdditionClearGeneralFilter.Visible = Not NoFilter2;
EndProcedure

&AtServer
Procedure SetAdditionDetailDescription()
	
	Text = DataExchangeServer.InteractiveExportChangeDetailedFilterDetails(ExportAddition);
	NoFilter2 = IsBlankString(Text);
	If NoFilter2 Then
		Text = NStr("vi = 'Chưa chọn dữ liệu bổ sung';
					|ru = 'Дополнительные данные не выбраны';
					|en = 'No additional data is selected'; fa = 'No additional data is selected';
					|it = 'Nessun dato aggiuntivo selezionato';
					|pl = 'Nie wybrano dodatkowych danych';
					|tr = 'Ek veri seçilmedi'");
	EndIf;
	
	Items.ExportAdditionDetailedFilter.Title = Text;
	Items.ExportAdditionClearDetailedFilter.Visible = Not NoFilter2;
EndProcedure

// Returns boolean - success or failure (setting is not found).
&AtServer 
Function ExportAdditionSetSettingsServer(SettingPresentation)
	Result = DataExchangeServer.InteractiveExportChangeRestoreSettings(ExportAddition, SettingPresentation);
	SetExportAdditionFilterDescription();
	Return Result;
EndFunction

&AtServer 
Function ExportAdditionServerSettingsHistory() 
	Return DataExchangeServer.InteractiveExportChangeSettingsHistory(ExportAddition);
EndFunction

#EndRegion

#EndRegion

#Region ProceduresAndFunctionsServerWIthoutContext

&AtServerNoContext
Procedure GetDataExchangesStates(DataImportResult, DataExportResult, Val InfobaseNode)
	
	DataExchangesStates = DataExchangeServer.DataExchangesStatesForInfobaseNode(InfobaseNode);
	
	DataImportResult = DataExchangesStates["DataImportResult"];
	If IsBlankString(DataExportResult) Then
		DataExportResult = DataExchangesStates["DataExportResult"];
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteMessageForDataMapping(Val ExchangeNode, Val TransportID = Undefined)
	
	SetPrivilegedMode(True);
	
	Filter = New Structure("InfobaseNode", ExchangeNode);
	CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);
	
	If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
		
		PassiveModeFileInformation = Common.FileInfobase() 
			And ExchangeMessagesTransport.TransportParameter(TransportID, "PassiveMode");
			
		MessageFileNameInStorage = DataExchangeServer.GetFileFromStorage(CommonSettings.MessageForDataMapping, PassiveModeFileInformation);
		
		File = New File(MessageFileNameInStorage);
		If File.Exists() And File.IsFile() Then
			DeleteFiles(MessageFileNameInStorage);
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(ExchangeNode, Undefined);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteTempExchangeMessagesDirectory(TempDirectoryName, DirectoryID)
	
	If Not IsBlankString(TempDirectoryName) Then
		
		Try
			DeleteFiles(TempDirectoryName);
			TempDirectoryName = "";
			If Not IsBlankString(DirectoryID) Then
				DataExchangeServer.GetFileFromStorage(DirectoryID);
			EndIf;
		Except
			WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Wait handlers

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	TimeConsumingOperationCompleted         = False;
	TimeConsumingOperationCompletedWithError = False;
	
	ActionState = DataExchangeServerCall.JobState(JobID);
	
	If ActionState = "Active" Or ActionState = "Active" Then
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 30, True);
	Else
		
		TimeConsumingOperation          = False;
		TimeConsumingOperationCompleted = True;
		
		If ActionState = "Failed" 
			Or ActionState = "Canceled" 
			Or ActionState = "Failed" Then
			TimeConsumingOperationCompletedWithError = True;
		EndIf;
		
		AttachIdleHandler("ExecuteMoveNext", 0.1, True);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the wizard.

&AtClient
Function GetSelectedRowKeys(SelectedRows)
	
	// Function return value.
	RowsKeys = New Array;
	
	For Each RowID In SelectedRows Do
		
		TreeRow = StatisticsInformationTree.FindByID(RowID);
		
		If Not IsBlankString(TreeRow.Key) Then
			
			RowsKeys.Add(TreeRow.Key);
			
		EndIf;
		
	EndDo;
	
	Return RowsKeys;
EndFunction

&AtClient
Procedure GetAllRowKeys(RowsKeys, TreeItemsCollection)
	
	For Each TreeRow In TreeItemsCollection Do
		
		If Not IsBlankString(TreeRow.Key) Then
			
			RowsKeys.Add(TreeRow.Key);
			
		EndIf;
		
		ItemsCollection = TreeRow.GetItems();
		
		If ItemsCollection.Count() > 0 Then
			
			GetAllRowKeys(RowsKeys, ItemsCollection);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RefreshDataExchangeStatusItemPresentation()
	
	Items.DataImportGroup.Visible = GetData;
	
	Items.DataImportStatusPages.CurrentPage = Items[DataExchangeClient.DataImportStatusPages()[DataImportResult]];
	If Items.DataImportStatusPages.CurrentPage=Items.ImportStatusUndefined Then
		Items.GoToDataImportEventLog.Title = NStr("vi = 'Chưa tiến hành kết nhập dữ liệu';
													|ru = 'Загрузка данных не произведена';
													|en = 'Data is not imported.'; fa = 'Data is not imported.';
													|it = 'Il download dei dati non è eseguito';
													|pl = 'Pobieranie danych nie dokonane';
													|tr = 'Veri içe aktarılmadı'");
	Else
		Items.GoToDataImportEventLog.Title = DataExchangeClient.DataImportHyperlinksHeaders()[DataImportResult];
	EndIf;
	
	Items.ErrorImportingMessageForMappingGroup.Visible = MessageReceivedForDataMapping And (DataImportResult = "Error");
	
	Items.DataExportGroup.Visible = SendData;
	
	Items.DataExportStatusPages.CurrentPage = Items[DataExchangeClient.DataExportStatusPages()[DataExportResult]];
	If Items.DataExportStatusPages.CurrentPage=Items.ExportStatusUndefined Then
		Items.GoToDataExportEventLog.Title = NStr("vi = 'Chưa tiến hành kết xuất dữ liệu';
													|ru = 'Выгрузка данных не произведена';
													|en = 'Data is not exported.'; fa = 'Data is not exported.';
													|it = 'L''importazione dei dati non è eseguita';
													|pl = 'Ładowanie danych nie zostało wykonane';
													|tr = 'Veri dışa aktarılmadı'");
	Else
		Items.GoToDataExportEventLog.Title = DataExchangeClient.DataExportHyperlinksHeaders()[DataExportResult];
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandStatisticsTree(RowKey = "")
	
	ItemsCollection = StatisticsInformationTree.GetItems();
	
	For Each TreeRow In ItemsCollection Do
		
		Items.StatisticsInformationTree.Expand(TreeRow.GetID(), True);
		
	EndDo;
	
	// Placing a mouse pointer in the value tree.
	If Not IsBlankString(RowKey) Then
		
		RowID = 0;
		
		CommonClientServer.GetTreeRowIDByFieldValue("Key", RowID, StatisticsInformationTree.GetItems(), RowKey, False);
		
		Items.StatisticsInformationTree.CurrentRow = RowID;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// BACKGROUND TASK PROCESSING SECTION

&AtClient
Function BackgroundJobParameters()
	
	JobParameters = New Structure();
	JobParameters.Insert("JobDescription",   "");
	JobParameters.Insert("MethodParameters",       Undefined);
	JobParameters.Insert("CallbackOnCompletion", Undefined);
	JobParameters.Insert("CompletionHandler",  Undefined);
	
	Return JobParameters;
	
EndFunction

&AtClient
Procedure RunBackgroundJobToReceiveExchangeMessageToTemporaryDirectory(JobParameters, Cancel, GetPasswordFromSessionData)
	
	Result = RunBackgroundJobToReceiveExchangeMessageToTemporaryDirectoryAtServer(JobParameters, GetPasswordFromSessionData);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If VersionDifferenceErrorOnGetData <> Undefined
		And VersionDifferenceErrorOnGetData.HasError Then
		Cancel = True;
		ErrorMessage = VersionDifferenceErrorOnGetData.ErrorText;
		Return;
	EndIf;
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult.Insert("CompletionHandler", JobParameters.CompletionHandler);
	
	If Result.Status = "Running" Then
		
		StartWaitingForEnd(Result);
		
	Else
		// The task is completed, canceled, or executed with an error.
		AttachIdleHandler(JobParameters.CompletionHandler, 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure RunBackgroundJobPerformAutomaticDataMatching(JobParameters, Cancel, GetPasswordFromSessionData)
	
	Result = RunBackgroundJobPerformAutomaticDataMatchingAtServer(JobParameters, GetPasswordFromSessionData);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If VersionDifferenceErrorOnGetData <> Undefined
		And VersionDifferenceErrorOnGetData.HasError Then
		Cancel = True;
		ErrorMessage = VersionDifferenceErrorOnGetData.ErrorText;
		Return;
	EndIf;
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult.Insert("CompletionHandler", JobParameters.CompletionHandler);
	
	If Result.Status = "Running" Then
		
		StartWaitingForEnd(Result);
		
	Else
		// The task is completed, canceled, or executed with an error.
		AttachIdleHandler(JobParameters.CompletionHandler, 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartBackgroundTaskLoadData(JobParameters, Cancel, GetPasswordFromSessionData)
	
	Result = RunBackgroundJobLoadDataAtServer(JobParameters, GetPasswordFromSessionData);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If VersionDifferenceErrorOnGetData <> Undefined
		And VersionDifferenceErrorOnGetData.HasError Then
		Cancel = True;
		ErrorMessage = VersionDifferenceErrorOnGetData.ErrorText;
		Return;
	EndIf;
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult.Insert("CompletionHandler", JobParameters.CompletionHandler);
	
	If Result.Status = "Running" Then
		
		StartWaitingForEnd(Result);
		
	Else
		// The task is completed, canceled, or executed with an error.
		AttachIdleHandler(JobParameters.CompletionHandler, 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartBackgroundTaskUploadData(JobParameters, Cancel, GetPasswordFromSessionData)
	
	Result = RunBackgroundJobUploadDataATServer(JobParameters, GetPasswordFromSessionData);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If VersionDifferenceErrorOnGetData <> Undefined
		And VersionDifferenceErrorOnGetData.HasError Then
		Cancel = True;
		ErrorMessage = VersionDifferenceErrorOnGetData.ErrorText;
		Return;
	EndIf;
	
	BackgroundJobExecutionResult = Result;
	BackgroundJobExecutionResult.Insert("CompletionHandler", JobParameters.CompletionHandler);
	
	If Result.Status = "Running" Then
		
		StartWaitingForEnd(Result);
		
	Else
		// The task is completed, canceled, or executed with an error.
		AttachIdleHandler(JobParameters.CompletionHandler, 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartWaitingForEnd(Result)
	
	TimeConsumingOperation = True;
	JobID = BackgroundJobExecutionResult.JobID;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow  = False;
	IdleParameters.OutputMessages     = True;
	
	BackgroundJobCompletionNotification = New CallbackDescription("BackgroundJobCompletionNotification", ThisObject);
	
	If UseProgressBar Then
		IdleParameters.OutputProgressBar = True;
		IdleParameters.ExecutionProgressNotification = New CallbackDescription("BackgroundJobExecutionProgress", ThisObject);
		IdleParameters.Interval = 1;
	EndIf;
	
	TimeConsumingOperationsClient.WaitCompletion(Result, BackgroundJobCompletionNotification, IdleParameters);
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ProgressStructure      = Progress.Progress;
		
		AdditionalProgressParameters = Undefined;
		If Not ProgressStructure.Property("AdditionalParameters", AdditionalProgressParameters) Then
			Return;
		EndIf;
		
		If Not AdditionalProgressParameters.Property("DataExchange") Then
			Return;
		EndIf;
		
		ProgressPercent       = ProgressStructure.Percent;
		ProgressAdditionalInformation = ProgressStructure.Text;
	EndIf;
	
EndProcedure

&AtServer
Function RunBackgroundJobToReceiveExchangeMessageToTemporaryDirectoryAtServer(Val JobParameters, Val GetPasswordFromSessionData)
	
	OperationStartDate  = CurrentSessionDate();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;

	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.GetExchangeMessageToTemporaryDirectory",
		JobParameters.MethodParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function RunBackgroundJobPerformAutomaticDataMatchingAtServer(Val JobParameters, Val GetPasswordFromSessionData)
	
	OperationStartDate  = CurrentSessionDate();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;

	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.ExecuteAutomaticDataMapping",
		JobParameters.MethodParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function RunBackgroundJobLoadDataAtServer(Val JobParameters, Val GetPasswordFromSessionData)
	
	OperationStartDate  = CurrentSessionDate();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;

	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.RunDataImport",
		JobParameters.MethodParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function RunBackgroundJobUploadDataATServer(Val JobParameters, Val GetPasswordFromSessionData)
	
	OperationStartDate  = CurrentSessionDate();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobParameters.JobDescription;

	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.RunDataExport",
		JobParameters.MethodParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure BackgroundJobCompletionNotification(Result, AdditionalParameters) Export
	
	CompletionHandler = BackgroundJobExecutionResult.CompletionHandler;
	BackgroundJobExecutionResult = Result;
	
	// Job is completed, canceled, or completed with an error.
	AttachIdleHandler(CompletionHandler, 0.1, True);
	
EndProcedure

&AtClient
Procedure ProcessBackgroundJobExecutionStatus(CurrentAction = Undefined)
	
	CommitCompletion = False;
	If TypeOf(BackgroundJobExecutionResult) <> Type("Structure") Then
		Return; 
	ElsIf BackgroundJobExecutionResult.Status = "Error" Then
		ErrorMessage = BackgroundJobExecutionResult.DetailErrorDescription;
		CommitCompletion = True;
	ElsIf BackgroundJobExecutionResult.Status = "Canceled" Then
		ErrorMessage = NStr("vi = 'Thao tác đã bị hủy bởi người sử dụng.';
							|ru = 'Действие отменено пользователем.';
							|en = 'The operation was canceled by user.'; fa = 'The operation was canceled by user.';
							|it = 'L''azione è stata annullata dall''utente.';
							|pl = 'Operacja została anulowana przez użytkownika.';
							|tr = 'Eylem kullanıcı tarafından iptal edildi.'");
		CommitCompletion = True;
	EndIf;
	
	If ValueIsFilled(CurrentAction)
		And CommitCompletion Then
		DataExchangeServerCall.WriteExchangeFinishWithError(
			Object.InfobaseNode,
			CurrentAction,
			OperationStartDate,
			ErrorMessage);
	EndIf;
		
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// SECTION OF STEP CHANGE HANDLERS

#Region NavigationEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Pages for checking whether synchronization is running.

&AtClient
Function Attachable_PageDataExchangeJobCheck_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If HasNodeScheduledExchange Then
		
		If ValueIsFilled(ScenarioUsingInternalPublication) Then
			
			Template = NStr("vi = 'Việc đồng bộ cho nút ""%1"" đã được lập kế hoạch 
                           |trong kịch bản ""%2"".
                           |
                           |Hãy nhấn Tiếp theo để hủy bỏ thực hiện kịch bản
                           |và khởi động đồng bộ theo nút.';
                           |ru = 'Синхронизация для узла ""%1"" уже запланирована 
                           |в сценарии ""%2"".
                           |
                           |Нажмите Далее, что бы отменить выполнение сценария
                           |и запустить синхронизацию по узлу.';
                           |en = 'Synchronization is already scheduled for node ""%1"" 
                           |in scenario ""%2"".
                           |
                           |Click Next to cancel the scenario
                           |and start synchronization by the node.'; fa = 'Synchronization is already scheduled for node ""%1"" 
                           |in scenario ""%2"".
                           |
                           |Click Next to cancel the scenario
                           |and start synchronization by the node.';
                           |it = 'La sincronizzazione del nodo ""%1"" è già programmata 
                           |nello scenario ""%2"".
                           |
                           |Cliccare Avanti per annullare l''esecuzione dello scenario
                           | e avviare la sincronizzazione del nodo.';
                           |pl = 'Synchronizacja dla węzła ""%1"" jest już zaplanowana 
                           |w scenariuszu ""%2"".
                           |
                           |Naciśnij Dalej, aby anulować wykonanie scenariusza
                           |i uruchomić synchronizację dla węzła.';
                           |tr = '""%1"" düğümü için senkronizasyon zaten
                           |""%2"" senaryosunda planlandı.
                           |
                           |Senaryonun yürütülmesini iptal etmek için
                           |ve düğümde senkronizasyonu başlatmak için İleri butonuna tıklayın.'");
			MessageText = StrTemplate(Template, String(Object.InfobaseNode), String(ScenarioUsingInternalPublication));	

		Else
			
			Template = NStr("vi = 'Đối với nút ""%1"" đã thực hiện đồng bộ.
                           |
                           |Hãy nhấn Tiếp theo để ngắt đồng bộ hiện tại
                           |và khởi động lại đồng bộ';
                           |ru = 'Для узла ""%1"" уже выполняется синхронизация.
                           |
                           |Нажмите Далее, что-бы прервать текущую синхронизации
                           |и запустить ее снова';
                           |en = 'Synchronization is already in progress for node ""%1"".
                           |
                           |Click Next to terminate the current synchronization
                           |and restart it'; fa = 'Synchronization is already in progress for node ""%1"".
                           |
                           |Click Next to terminate the current synchronization
                           |and restart it';
                           |it = 'La sincronizzazione del nodo ""%1"" è già in esecuzione.
                           |
                           |Cliccare Avanti per interrompere la sincronizzazione corrente 
                           | e riavviarla';
                           |pl = 'Dla węzła ""%1"" już trwa synchronizacja.
                           |
                           |Naciśnij Dalej, aby przerwać bieżącą synchronizację
                           |i uruchomić jej ponownie';
                           |tr = '""%1"" düğümü için senkronizasyon zaten yapılıyor.
                           |
                           |Geçerli senkronizasyonu durdurmak ve yeniden başlatmak için
                           |İleri butonuna tıklayın'");
			MessageText = StrTemplate(Template, String(Object.InfobaseNode));

		EndIf;
		
		Items.StatusTaskQueued.Title = MessageText;
		
	Else
		
		SkipPage = True;
		
	EndIf;
		
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageDataExchangeTasksCheck_OnNavigateNext(Cancel)
	
	CancelQueueAndResumeOnServer();
	Return Undefined;
	
EndFunction

&AtServer
Procedure CancelQueueAndResumeOnServer()
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
		ModuleDataExchangeInternalPublication.CancelTaskQueue(Object.InfobaseNode, 
			ScenarioUsingInternalPublication,
			IDOfExchangeViaInternalPublication,
			CorrespondentDataArea);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Pages for processing data receipt (transport of the exchange message).

&AtClient
Function Attachable_DataAnalysisWaitingPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	InitializeDataProcessorVariables();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataAnalysisWaitingPageTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	SkipGettingData = False;
	GoToNext              = False;
	
	GetPasswordFromSessionData = False;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("Cancel", False);
	MethodParameters.Insert("TimeConsumingOperation",                   TimeConsumingOperation);
	MethodParameters.Insert("OperationID",                OperationID);
	MethodParameters.Insert("DataPackageFileID",       DataPackageFileID);
	MethodParameters.Insert("FileID",                   FileID);
	MethodParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	MethodParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	MethodParameters.Insert("TempExchangeMessagesDirectoryName", Object.TempExchangeMessagesDirectoryName);
	
	MethodParameters.Insert("TransportID", Object.TransportID);
	MethodParameters.Insert("AuthenticationData", AuthenticationData);
	MethodParameters.Insert("MessageReceivedForDataMapping", MessageReceivedForDataMapping);
	MethodParameters.Insert("TempDirectoryIDForExchange", "");
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("vi = 'Nhận thông điệp trao đổi trong thư mục tạm thời';
										|ru = 'Получение сообщения обмена во временный каталог';
										|en = 'Get exchange message to temporary directory'; fa = 'Get exchange message to temporary directory';
										|it = 'Ricezione del messaggio di scambio in una directory temporanea';
										|pl = 'Otrzymanie wiadomości wymiany do katalogu tymczasowego';
										|tr = 'Alışveriş mesajı geçici dizine alınıyor'");
	JobParameters.CompletionHandler = "DataReceiptToTemporaryFolderCompletion";
	
	RunBackgroundJobToReceiveExchangeMessageToTemporaryDirectory(JobParameters, Cancel, GetPasswordFromSessionData);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure DataReceiptToTemporaryFolderCompletion()
	
	ProcessBackgroundJobExecutionStatus("DataImport");
	
	If ValueIsFilled(ErrorMessage) Then
		SkipGettingData = True;
	Else
		GetDataToTemporaryDirectoryAtServerCompletion();
	EndIf;
	
	If TimeConsumingOperation And Not SkipGettingData Then
		RetryCountOnConnectionError = 0;
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		AttachIdleHandler("ExecuteMoveNext", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDataToTemporaryDirectoryAtServerCompletion()
	
	ErrorMessageTemplate = NStr("vi = 'Không thể kết nhập dữ liệu. Chi tiết xem trong nhật ký sự kiện';
								|ru = 'Не удалось выполнить загрузку данных. Подробности см. в журнале регистрации';
								|en = 'Cannot import data. See the event log for details.'; fa = 'Cannot import data. See the event log for details.';
								|it = 'Impossibile eseguire il download dei dati. Vedere il registro per i dettagli';
								|pl = 'Nie udało się wykonać pobieranie danych. Szczegóły można znaleźć w dzienniku rejestracji';
								|tr = 'Veriler içe aktarılamadı. Ayrıntılar için olay günlüğüne bakın'");
	MethodExecutionResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
	
	If MethodExecutionResult = Undefined Then
		If Not ValueIsFilled(ErrorMessage) Then
			ErrorMessage = ErrorMessageTemplate;
		EndIf;
	Else
		
		If MethodExecutionResult.Cancel Then
			
			If MethodExecutionResult.Property("ErrorMessage") Then
				ErrorMessage = MethodExecutionResult.ErrorMessage;
			ElsIf Not ValueIsFilled(ErrorMessage) Then
				ErrorMessage = ErrorMessageTemplate;
			EndIf;
			
			If MessageReceivedForDataMapping Then
				MessageReceivedForDataMapping = False;
			EndIf;
			
		Else
			
			Object.ExchangeMessageFileName              = MethodExecutionResult.ExchangeMessageFileName;
			Object.TempExchangeMessagesDirectoryName = MethodExecutionResult.TempExchangeMessagesDirectoryName;
			
		EndIf;
			
	EndIf;
	
	If ValueIsFilled(ErrorMessage) Then
		
		TimeConsumingOperation                  = False;
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		SkipGettingData           = True;
		
		DataExchangeServerCall.WriteExchangeFinishWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorMessage);
			
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data analysis pages (automatic data matching).

&AtClient
Function Attachable_DataAnalysisPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If SkipGettingData Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataAnalysisTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If SkipGettingData Then
		Return Undefined;
	EndIf;
	
	GoToNext = False;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("InfobaseNode",               Object.InfobaseNode);
	MethodParameters.Insert("ExchangeMessageFileName",              Object.ExchangeMessageFileName);
	MethodParameters.Insert("TempExchangeMessagesDirectoryName", Object.TempExchangeMessagesDirectoryName);
	MethodParameters.Insert("CheckVersionDifference",           CheckVersionDifference);
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("vi = 'Phân tích dữ liệu có thông điệp trao đổi';
										|ru = 'Анализ данных сообщения обмена';
										|en = 'Analyze exchange message data'; fa = 'Analyze exchange message data';
										|it = 'Analisi dei dati del messaggio di scambio';
										|pl = 'Analiza danych wiadomości wymiany';
										|tr = 'Alışveriş mesajı verilerinin analizi'");
	JobParameters.CompletionHandler = "Attachable_DataAnalysisCompletion";
	
	RunBackgroundJobPerformAutomaticDataMatching(JobParameters, Cancel, False);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure Attachable_DataAnalysisCompletion()
	
	ProcessBackgroundJobExecutionStatus("DataImport");
	
	If Not SkipGettingData And ValueIsFilled(ErrorMessage) Then
		SkipGettingData = True;
	Else
		AtalyzeDataAtServerCompletion();
	EndIf;
	
	If ForceCloseForm Then
		Close();
	EndIf;

	If Not SkipGettingData Then
		ExpandStatisticsTree();
	EndIf;
	
	AttachIdleHandler("ExecuteMoveNext", 0.1, True);
	
EndProcedure

&AtServer
Procedure AtalyzeDataAtServerCompletion()
	
	// Checking the transition to a new data exchange.
	CheckWhetherTransferToNewExchangeIsRequired();
	If ForceCloseForm Then
		Return;
	EndIf;
	
	Try
		
		AnalysisResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
		
		If AnalysisResult.Property("ErrorText") Then
			VersionDifferenceErrorOnGetData = AnalysisResult;
		ElsIf AnalysisResult.Cancel Then
			
			If AnalysisResult.Property("ExchangeExecutionResult")
				And AnalysisResult.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted Then
				
				SkipGettingData = True;
				
				ExchangeSettingsStructure = New Structure;
				ExchangeSettingsStructure.Insert("InfobaseNode",       Object.InfobaseNode);
				ExchangeSettingsStructure.Insert("ExchangeExecutionResult",    AnalysisResult.ExchangeExecutionResult);
				ExchangeSettingsStructure.Insert("ActionOnExchange",            "DataImport");
				ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
				ExchangeSettingsStructure.Insert("StartDate",                   OperationStartDate);
				ExchangeSettingsStructure.Insert("EndDate",                CurrentSessionDate());
				ExchangeSettingsStructure.Insert("EventLogMessageKey", 
					DataExchangeServer.EventLogMessageKey(Object.InfobaseNode, "DataImport"));
				ExchangeSettingsStructure.Insert("IsDIBExchange", 
					DataExchangeCached.IsDistributedInfobaseNode(Object.InfobaseNode));
				
				DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
			Else
				Raise AnalysisResult.ErrorMessage;
			EndIf;
			
		Else
			
			AllDataMapped   = AnalysisResult.AllDataMapped;
			HasUnmappedMasterData = AnalysisResult.HasUnmappedMasterData;
			StatisticsBlank        = AnalysisResult.StatisticsBlank;
			
			Object.StatisticsInformation.Load(AnalysisResult.StatisticsInformation);
			Object.StatisticsInformation.Sort("Presentation");
			
			StatisticsInformation(Object.StatisticsInformation.Unload());
			
			SetAdditionalInfoGroupVisible();
			
		EndIf;
		
	Except
		SkipGettingData = True;
		
		Information = ErrorInfo();
		ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		
		DataExchangeServerCall.WriteExchangeFinishWithError(
			Object.InfobaseNode,
			"DataImport",
			OperationStartDate,
			ErrorProcessing.DetailErrorDescription(Information));
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data mapping processing pages (interactive data mapping).

&AtClient
Function Attachable_StatisticsInformationPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If StatisticsBlank Or SkipGettingData Then
		SkipPage = True;
		If MessageReceivedForDataMapping Then
			EndDataMapping = StatisticsBlank;
		EndIf;
	EndIf;
	
	If Not SkipPage Then
		Items.MappingCompletionGroup.Visible = MessageReceivedForDataMapping;
		OnChangeFlagEndDataMapping();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_StatisticsInformationPageOnGoNext(Cancel)
	
	If StatisticsBlank Or SkipGettingData Or AllDataMapped Or Not HasUnmappedMasterData Then
		Return Undefined;
	EndIf;
	
	If SkipCurrentPageCancelControl = True Then
		SkipCurrentPageCancelControl = Undefined;
		Return Undefined;
	EndIf;
	
	// Going to the next page after user confirmation.
	Cancel = True;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes,  NStr("vi = 'Tiếp tục';
											|ru = 'Продолжить';
											|en = 'Continue'; fa = 'ادامه';
											|it = 'Continuare';
											|pl = 'Kontynuuj';
											|tr = 'Devam'"));
	Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Anuluj';
											|tr = 'İptal'"));
	
	Message = NStr("vi = 'Không phải tất cả dữ liệu đều được so sánh. Có dữ liệu chưa được so sánh
	                       |có thể dẫn đến xuất hiện các phần tử giống nhau trong danh sách (phần tử trùng lặp).
	                       |Tiếp tục?';
	                       |ru = 'Не все данные сопоставлены. Наличие несопоставленных данных
	                       |может привести к появлению одинаковых элементов в списках (дублей).
	                       |Продолжить?';
	                       |en = 'Unmapped data is found. This might result in
	                       |duplication of list items.
	                       |Do you want to continue?'; fa = 'Unmapped data is found. This might result in
	                       |duplication of list items.
	                       |Do you want to continue?';
	                       |it = 'Non tutti i dati sono associati. La presenza di dati non associati
	                       |può portare alla comparsa di elementi identici negli elenchi (duplicati).
	                       |Continuare?';
	                       |pl = 'Nie wszystkie dane są dopasowane. Obecność niedopasowanych danych
	                       |może doprowadzić do pojawienia się identycznych elementów w listach (duplikatów).
	                       |Kontynuować?';
	                       |tr = 'Verilerin hepsi karşılaştırılmadı. Eşleşmeyen verilerin
	                       | varlığı aynı katalog öğelerinin oluşmasına yol açabilir (çiftler).
	                       |Devam edilsin mi?'");
	
	Notification = New CallbackDescription("StatisticsPageOnGoNextQuestionCompletion", ThisObject);
	
	ShowQueryBox(Notification, Message, Buttons,, DialogReturnCode.Yes);
	
	Return Undefined;
	
EndFunction

// Continuation of the procedure (see above).
&AtClient
Procedure StatisticsPageOnGoNextQuestionCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	AttachIdleHandler("Attachable_GoStepForwardWithDeferredProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure Attachable_GoStepForwardWithDeferredProcessing()
	
	// Going a step forward (forced).
	SkipCurrentPageCancelControl = True;
	ChangeNavigationNumber( +1 );
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data Loading Processing Pages

&AtClient
Function Attachable_DataImportOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If SkipGettingData Then
		SkipPage = True;
		If Not MessageReceivedForDataMapping Then
			DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessagesDirectoryName, TempDirectoryIDForExchange);
		EndIf;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataImportTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If SkipGettingData Then
		DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessagesDirectoryName, TempDirectoryIDForExchange);
		Return Undefined;
	EndIf;
	
	GoToNext    = False;
	MethodParameters = New Structure;
	MethodParameters.Insert("InfobaseNode",  Object.InfobaseNode);
	MethodParameters.Insert("ExchangeMessageFileName", Object.ExchangeMessageFileName);
	
	JobParameters = BackgroundJobParameters();
	JobParameters.MethodParameters      = MethodParameters;
	JobParameters.JobDescription  = NStr("vi = 'Kết nhập dữ liệu từ thông điệp trao đổi';
										|ru = 'Загрузка данных из сообщения обмена';
										|en = 'Import data from exchange message'; fa = 'Import data from exchange message';
										|it = 'Il download dei dati dal messaggio di scambio';
										|pl = 'Pobieranie danych z wiadomości wymiany';
										|tr = 'Verileri alışveriş mesajından içe aktar'");
	JobParameters.CompletionHandler = "DataImportCompletion";
	
	StartBackgroundTaskLoadData(JobParameters, Cancel, False);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure DataImportCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	If ValueIsFilled(ErrorMessage) And Not SkipGettingData Then
		SkipGettingData = True;
	EndIf;
	
	ProgressBarDisplayed = Items.PanelMain.CurrentPage = Items.DataSynchronizationWaitProgressBarImportPage
		Or Items.PanelMain.CurrentPage = Items.DataSynchronizationWaitProgressBarExportPage;
		
	If UseProgressBar And ProgressBarDisplayed Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	If MessageReceivedForDataMapping Then
		
		CurrentDataImportResult = "";
		CurrentDataExportResult = "";
		GetDataExchangesStates(CurrentDataImportResult, CurrentDataExportResult, Object.InfobaseNode);
		
		If (EndDataMapping And Not SkipGettingData)
			Or (CurrentDataImportResult = "Warning_ExchangeMessageAlreadyAccepted") Then
			DeleteMessageForDataMapping(Object.InfobaseNode, Object.TransportID); 
		EndIf;
		
	EndIf;
		
	AttachIdleHandler("ExecuteMoveNext", 0.1, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Additional upload pages (registration for uploading additional data).

&AtClient
Function Attachable_QuestionAboutExportCompositionPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ExportAddition.ExportOption < 0 Then
		// According to the node settings, the addition of export is not performed, go to the next page.
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataRegistrationPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If ExportAddition.ExportOption < 0 Then
		// According to the node settings, the addition of export is not performed, go to the next page.
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataRegistrationPageTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	AttachIdleHandler("OnStartRecordData", 0.1, True);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartRecordData()
	
	ContinueWait = True;
	OnStartRecordDataAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			DataRegistrationIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForRecordData",
			DataRegistrationIdleHandlerParameters.CurrentInterval, True);
	Else
		AttachIdleHandler("OnCompleteDataRecording", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForRecordData()
	
	ContinueWait = False;
	OnWaitForRecordDataAtServer(DataRegistrationHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataRegistrationIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForRecordData",
			DataRegistrationIdleHandlerParameters.CurrentInterval, True);
	Else
		AttachIdleHandler("OnCompleteDataRecording", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataRecording()
	
	DataRegistered = False;
	ErrorMessage = "";
	
	OnCompleteDataRecordingAtServer(DataRegistrationHandlerParameters, DataRegistered, ErrorMessage);
	
	If DataRegistered Then
		
		ChangeNavigationNumber(+1);
		
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("vi = 'Không thể ghi nhận dữ liệu để kết xuất.';
					|ru = 'Не удалось зарегистрировать данные для выгрузки.';
					|en = 'Cannot register data to export.'; fa = 'Cannot register data to export.';
					|it = 'Impossibile registrare i dati per upload.';
					|pl = 'Nie udało się zarejestrować dane do ładowania.';
					|tr = 'Dışa aktarılacak veriler kaydedilemedi.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartRecordDataAtServer(ContinueWait)
	
	RegistrationSettings = New Structure;
	RegistrationSettings.Insert("ExchangeNode", ExportAddition.InfobaseNode);
	RegistrationSettings.Insert("ExportAddition", Undefined);
	
	PrepareExportAdditionStructure(RegistrationSettings.ExportAddition);
	
	DataRegistrationHandlerParameters = Undefined;
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnStartRecordData(RegistrationSettings,
		DataRegistrationHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForRecordDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnWaitForRecordData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataRecordingAtServer(HandlerParameters, DataRegistered, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	ModuleInteractiveExchangeWizard.OnCompleteDataRecording(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataRegistered = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		DataRegistered = CompletionStatus.Result.DataRegistered;
		
		If Not DataRegistered Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Data Upload Processing Pages

&AtClient
Function Attachable_DataExportOnOpen(Cancel, SkipPage, IsMoveNext)
	
	InitializeDataProcessorVariables();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportWaitingPageTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartExportData(Cancel);
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartExportData(Cancel)
	
	If ExchangeBetweenSaaSApplications Then
		ContinueWait = True;
		OnStartExportDataAtServer(ContinueWait);
		
		If ContinueWait Then
			DataExchangeClient.InitIdleHandlerParameters(
				DataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportData",
				DataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			OnCompleteDataExport();
		EndIf;

	ElsIf ExchangeViaInternalPublication Then
		
		OnStartExportDataViaInternalPublicationAtServer();
		
		DataExchangeClient.InitIdleHandlerParameters(
			DataExportIdleHandlerParameters);

		AttachIdleHandler("OnWaitDataExportViaInternalPublication",
			DataExportIdleHandlerParameters.CurrentInterval, True);
		
	Else
		GetPasswordFromSessionData = False;
		
		MethodParameters = New Structure;
		MethodParameters.Insert("InfobaseNode", Object.InfobaseNode);
		MethodParameters.Insert("TransportID", Object.TransportID);
		MethodParameters.Insert("ExchangeMessageFileName", Object.ExchangeMessageFileName);
		MethodParameters.Insert("TimeConsumingOperation", TimeConsumingOperation);
		MethodParameters.Insert("OperationID", OperationID);
		MethodParameters.Insert("FileID", FileID);
		MethodParameters.Insert("AuthenticationData", AuthenticationData);
		MethodParameters.Insert("Cancel", False);
		
		JobParameters = BackgroundJobParameters();
		JobParameters.MethodParameters      = MethodParameters;
		JobParameters.JobDescription  = NStr("vi = 'Kết xuất dữ liệu vào thông điệp trao đổi';
											|ru = 'Выгрузка данных в сообщение обмена';
											|en = 'Export data to exchange message'; fa = 'Export data to exchange message';
											|it = 'Upload dei dati dal messaggio di scambio';
											|pl = 'Ładowanie danych do wiadomości wymiany';
											|tr = 'Verilerin alışveriş mesajına dışa aktarılması'");
		JobParameters.CompletionHandler = "DataExportCompletion";
		
		StartBackgroundTaskUploadData(JobParameters, Cancel, GetPasswordFromSessionData);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportData()
	
	ContinueWait = False;
	OnWaitForExportDataAtServer(DataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportData",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExport()
	
	DataExported1 = False;
	ErrorMessage = "";
	
	OnCompleteDataUnloadAtServer(DataExportHandlerParameters, DataExported1, ErrorMessage);
	
	If DataExported1 Then
		ChangeNavigationNumber(+1);
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("vi = 'Không thể thực hiện trao đổi dữ liệu.';
					|ru = 'Не удалось выполнить обмен данными.';
					|en = 'Cannot perform data exchange.'; fa = 'Cannot perform data exchange.';
					|it = 'Scambio di dati fallito.';
					|pl = 'Nie udało się wykonać wymianę danych.';
					|tr = 'Veri alışverişi yapılamadı.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartExportDataAtServer(ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ExportSettings1 = New Structure;
	ExportSettings1.Insert("Peer", Object.InfobaseNode);
	ExportSettings1.Insert("CorrespondentDataArea", CorrespondentDataArea);
	ExportSettings1.Insert("ExportAddition", Undefined);
	
	PrepareExportAdditionStructure(ExportSettings1.ExportAddition);
	
	DataExportHandlerParameters = Undefined;
	ModuleInteractiveExchangeWizard.OnStartExportData(ExportSettings1,
		DataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForExportDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataUnloadAtServer(HandlerParameters, DataExported1, ErrorMessage)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExported1 = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteDataExport(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataExported1 = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		DataExported1 = CompletionStatus.Result.DataExported1;
		
		If Not DataExported1 Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DataExportCompletion()
	
	ProcessBackgroundJobExecutionStatus();
	
	ProgressBarDisplayed = Items.PanelMain.CurrentPage = Items.DataSynchronizationWaitProgressBarImportPage
		Or Items.PanelMain.CurrentPage = Items.DataSynchronizationWaitProgressBarExportPage;
	
	If UseProgressBar And ProgressBarDisplayed Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	DataExportCompletionAtServer();
	
	If TimeConsumingOperation And Not ValueIsFilled(ErrorMessage) Then
		RetryCountOnConnectionError = 0;
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
	Else
		DeleteTempExchangeMessagesDirectory(Object.TempExchangeMessagesDirectoryName, TempDirectoryIDForExchange);
		AttachIdleHandler("ExecuteMoveNext", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure DataExportCompletionAtServer()
	
	MethodExecutionResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
	
	If MethodExecutionResult = Undefined Then
		MethodExecutionResult = New Structure("Cancel", True);
	Else
		FillPropertyValues(ThisObject, MethodExecutionResult, 
			"TimeConsumingOperation, OperationID, FileID");
	EndIf;
	
	If MethodExecutionResult.Cancel
		And Not ValueIsFilled(ErrorMessage) Then
		ErrorMessage = NStr("vi = 'Không thể gửi dữ liệu. Chi tiết xem trong nhật ký sự kiện';
							|ru = 'Не удалось выполнить отправку данных. Подробности см. в журнале регистрации';
							|en = 'Cannot send data. See the event log for details.'; fa = 'Cannot send data. See the event log for details.';
							|it = 'Impossibile inviare dati. Vedere il registro per i dettagli';
							|pl = 'Nie udało się wykonać wysyłanie danych. Szczegóły można znaleźć w dzienniku rejestracji';
							|tr = 'Veriler gönderilemedi. Ayrıntılar için olay günlüğüne bakın'");
	EndIf;
	
	If ValueIsFilled(ErrorMessage) Then
		
		TimeConsumingOperation                  = False;
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		
		DataExchangeServerCall.WriteExchangeFinishWithError(
			Object.InfobaseNode,
			"DataExport",
			OperationStartDate,
			ErrorMessage);
			
	EndIf;
	
EndProcedure

&AtServer 
Procedure OnStartExportDataViaInternalPublicationAtServer()
	
	StructureAddition = Undefined;
	PrepareExportAdditionStructure(StructureAddition);
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.RunDataExchangeManually(Object.InfobaseNode, 
		ParametersOfExchangeViaInternalPublication, StructureAddition);
	
EndProcedure
	
&AtClient
Procedure OnWaitDataExportViaInternalPublication()
	
	ContinueWait = False;
	OnWaitDataExportViaInternalPublicationAtServer(ParametersOfExchangeViaInternalPublication, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitDataExportViaInternalPublication",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExportViaInternalPublication();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure OnWaitDataExportViaInternalPublicationAtServer(ExchangeParameters, ContinueWait)

	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.OnWaitForExportData(ExchangeParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure OnCompleteDataExportViaInternalPublication()
			
	OutputErrorDescriptionToUser = True;
	ErrorMessage = ParametersOfExchangeViaInternalPublication.ErrorMessage;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Summary Information Pages

&AtClient
Function Attachable_MappingCompletePageOnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	GetDataExchangesStates(DataImportResult, DataExportResult, Object.InfobaseNode);
	
	RefreshDataExchangeStatusItemPresentation();
	
	ForceCloseForm = True;
	
	Return Undefined;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// TRANSITION INITIALIZATION SECTION

&AtServer
Procedure FillNavigationTable()
	
	If UseProgressBar Then
		PageNameSynchronizationImport = "DataSynchronizationWaitProgressBarImportPage";
		PageNameSynchronizationExport = "DataSynchronizationWaitProgressBarExportPage";
	Else
		PageNameSynchronizationImport = "DataSynchronizationWaitPage";
		PageNameSynchronizationExport = "DataSynchronizationWaitPage";
	EndIf;
	
	NavigationTable.Clear();
	
	If ExchangeBetweenSaaSApplications Then
		
		If MessageReceivedForDataMapping Then
			// Getting data (exchange message transport.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, 
				"Attachable_DataAnalysisWaitingPageTimeConsumingOperationProcessing",
				"Attachable_DataAnalysisWaitingPageOnOpen");
			
			// Data analysis pages (automatic data mapping).
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, 
				"Attachable_DataAnalysisTimeConsumingOperationProcessing",
				"Attachable_DataAnalysisPageOnOpen");
			
			// Manual data mapping.
			NavigationTableNewRow("StatisticsInformationPage", "StatisticsInformationNavigationPage", 
				"Attachable_StatisticsInformationPageOnOpen",
				"Attachable_StatisticsInformationPageOnGoNext");
			
			// Data import.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationImport, "NavigationWaitPage", True,
				"Attachable_DataImportTimeConsumingOperationProcessing",
				"Attachable_DataImportOnOpen");
			
		ElsIf SendData Then
			
			If ExportAdditionMode Then
				DataExportResult = "";
				NavigationTableNewRow("QuestionAboutExportCompositionPage", "NavigationPageFollowUp", "Attachable_QuestionAboutExportCompositionPageOnOpen");
			EndIf;
			
			// Export and import data.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationExport, "NavigationWaitPage", True, 
				"Attachable_DataExportWaitingPageTimeConsumingOperationProcessing",
				"Attachable_DataExportOnOpen");
		EndIf;
		
	Else
		
		If GetData Then
			// Getting data (exchange message transport.
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, 
				"Attachable_DataAnalysisWaitingPageTimeConsumingOperationProcessing",
				"Attachable_DataAnalysisWaitingPageOnOpen");
			
			// Data analysis pages (automatic data mapping).
			NavigationTableNewRowTimeConsumingOperation("DataAnalysisWaitPage", "NavigationWaitPage", True, 
				"Attachable_DataAnalysisTimeConsumingOperationProcessing",
				"Attachable_DataAnalysisPageOnOpen");
			
			// Manual data mapping.
			If MessageReceivedForDataMapping Then
				NavigationTableNewRow("StatisticsInformationPage", "StatisticsInformationNavigationPage", 
					"Attachable_StatisticsInformationPageOnOpen",
					"Attachable_StatisticsInformationPageOnGoNext");
			Else
				NavigationTableNewRow("StatisticsInformationPage", "NavigationPageFollowUp", 
					"Attachable_StatisticsInformationPageOnOpen",
					"Attachable_StatisticsInformationPageOnGoNext");
			EndIf;
			
			// Data import.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationImport, "NavigationWaitPage", True, 
				"Attachable_DataImportTimeConsumingOperationProcessing",
				"Attachable_DataImportOnOpen");
		EndIf;
		
		If SendData Then
			
			If ExchangeViaInternalPublication Then
				NavigationTableNewRow("PageCheckExchangeTasks", "NavigationPageFollowUp", 
					"Attachable_PageDataExchangeJobCheck_OnOpen",
					"Attachable_PageDataExchangeTasksCheck_OnNavigateNext");
			EndIf;
			
			If ExportAdditionMode Then
				// Data export setup.
				DataExportResult = "";
				NavigationTableNewRow("QuestionAboutExportCompositionPage", "NavigationPageFollowUp", "Attachable_QuestionAboutExportCompositionPageOnOpen");
				
				// The long-running operation of registering additional data to export.
				NavigationTableNewRowTimeConsumingOperation("DataRegistrationPage", "NavigationWaitPage", True,
					"Attachable_DataRegistrationPageTimeConsumingOperationProcessing",
					"Attachable_DataRegistrationPageOnOpen");
			EndIf;
			
			// Export data.
			NavigationTableNewRowTimeConsumingOperation(PageNameSynchronizationExport, "NavigationWaitPage", True,
				"Attachable_DataExportWaitingPageTimeConsumingOperationProcessing",
				"Attachable_DataExportOnOpen");
		EndIf;
		
	EndIf;
	
	// Totals.
	NavigationTableNewRow("MappingCompletePage", "NavigationEndPage", "Attachable_MappingCompletePageOnOpen");
	
EndProcedure

#EndRegion

#EndRegion
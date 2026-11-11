
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	TMCommonUse.CustomizePeripherals(ThisObject);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	OrganizationOldValue = Object.Organization;
	
	ParametersForProcessingGiftCertificates = GiftCertificatesServerCall.ParametersForProcessingReceivedCode();
	ParametersForProcessingGiftCertificates.RegisterNewOnes = False;
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Returned__"));
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.FullyRepaid"));
	
	FilterStructure1 = ParametersForProcessingGiftCertificates.Filters;
	FilterStructure1.Insert("Status", ArrayOfStatuses);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
	
	SetSelectionParametersForGiftCertificate(ThisObject);
	
	// Control of document creation in a subordinate RIB node with filters
	DataExchangeTMERP.ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
		
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	ManagingItemAvailability();
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner,MagneticStripeCardReaders");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
		
	EndIf;
		
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ManagingItemAvailability();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Object.Organization <> OrganizationOldValue 
		And Object.GiftCertificates.Count() Then
		ShowQueryBox(
				New CallbackDescription("OrganizationOnChangeCompletion", ThisObject),
				NStr("vi = 'Khi thay đổi doanh nghiệp trong chứng từ, bảng ""Phiếu quà tặng"" sẽ bị xóa. Tiếp tục?';
					|ru = 'При изменении организации документа таблица ""Подарочные сертификаты"" будет очищена. Продолжить?';
					|en = 'When you change the company mentioned in the document, the Gift cards table will be cleared. Continue?'; fa = 'When you change the company mentioned in the document, the Gift cards table will be cleared. Continue?';
					|it = 'In caso di modifiche all''azienda del documento, la tabella ""Buoni regalo"" sarà cancellata. Continuare?';
					|pl = 'Podczas zmiany firmy dokumentu tabela ""Certyfikaty podarunkowe"" zostaną wyczyszczone. Kontynuować?';
					|tr = 'Belge iş yeri değiştirilirse, ""Hediye Kuponları"" tablosu temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		OrganizationOnChangeCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.GiftCertificates.Clear();
		OrganizationOldValue = Object.Organization;
		ParametersForProcessingGiftCertificates.Filters.Organization =  Object.Organization;
		SetSelectionParametersForGiftCertificate(ThisObject);
	Else
		Object.Organization = OrganizationOldValue;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGiftCertificates

&AtClient
Procedure GiftCertificatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	// Interactive adding and copying of table rows is prohibited on the form.
	Cancel = True;
EndProcedure

&AtClient
Procedure GiftCertificatesGiftCertificateStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	ParametersStructure = New Structure("Filter", ParametersForProcessingGiftCertificates.Filters);	
	OpenForm("Catalog.GiftCertificates.ChoiceForm", ParametersStructure, ThisObject,,,, 
	                         New CallbackDescription("GiftCertificatesGiftCertificateStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure GiftCertificatesGiftCertificateStartChoiceCompletion(Result, AdditionalParameters) Export
	SelectedCertificate = Result;
	If SelectedCertificate = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.GiftCertificates.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.GiftCertificate = SelectedCertificate;
		ProcessGiftCertificate(SelectedCertificate);
	EndIf; 	
EndProcedure

&AtClient
Procedure GiftCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GiftCertificatesGiftCertificate Then
		ShowValue(Undefined, Items.GiftCertificates.CurrentData.GiftCertificate);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	ClearMessages();
	If Not ValueIsFilled(Object.Organization) Then
		MessageText = NStr("vi = 'Trước khi điền, cần chọn doanh nghiệp.';
							|ru = 'Перед заполнением необходимо выбрать организацию.';
							|en = 'Before filling, select a company.'; fa = 'Before filling, select a company.';
							|it = 'Prima della compilazione è necessario selezionare l''azienda.';
							|pl = 'Przed wypełnieniem należy wybrać firmę.';
							|tr = 'Doldurmadan önce bir iş yeri seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(MessageText,,"Organization", "Object.Organization"); 
	EndIf;
	
	DescriptionOfAssuranceNotification = New CallbackDescription("FillContinued", ThisObject);
	If Object.Posted Then
		RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, DescriptionOfAssuranceNotification);
	Else
		RunCallback(DescriptionOfAssuranceNotification, True);
	EndIf;
		
EndProcedure

&AtClient
Procedure FillContinued(Result, AdditionalParameters) Export
	
	If Result = True Then
		If Object.GiftCertificates.Count() Then
			ShowQueryBox(
					New CallbackDescription("FillCompletion", ThisObject),
					NStr("vi = 'Trước khi điền, bảng ""Phiếu quà tặng"" sẽ bị xóa. Tiếp tục?';
						|ru = 'Перед заполнением таблица ""Подарочные сертификаты"" будет очищена. Продолжить?';
						|en = 'Before filling, the Gift cards table will be cleared. Continue?'; fa = 'Before filling, the Gift cards table will be cleared. Continue?';
						|it = 'Prima della compilazione la tabella ""Buoni regalo"" sarà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem tabela ""Certyfikaty podarunkowe"" zostanie wyczyszczona. Kontynuować?';
						|tr = 'Doldurmadan önce ""Hediye Kuponları"" tablosu temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
					
		Else
			FillCompletion(DialogReturnCode.Yes, Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillCompletion(Result, AdditionalParameters) Export
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.GiftCertificateCancellation.Form.DocumentForm.FillCompletion");
	
	If Result = DialogReturnCode.Yes Then
		FillInTablePartGiftCertificates();
	EndIf;	
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure ConsiderAGiftCertificate(Command)

	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject, False) Then
		DescriptionOfAssuranceNotification = New CallbackDescription("ConsiderAGiftCertificateCompletion", ThisObject);
		If Object.Posted Then
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, DescriptionOfAssuranceNotification);
		Else
			RunCallback(DescriptionOfAssuranceNotification, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConsiderAGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("DoNotUseManualInput", False);
		FormOpenParameters.Insert("Filter", ParametersForProcessingGiftCertificates.Filters);
		FormOpenParameters.Insert("RegisterNewOnes", ParametersForProcessingGiftCertificates.RegisterNewOnes);
		
		OpenForm(
			"Catalog.GiftCertificates.Form.ReadGiftCard",
			FormOpenParameters,
			ThisObject,
			UUID);
	EndIf;
		
EndProcedure	

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ManagingItemAvailability()
	
	Items.GiftCertificates.ReadOnly = Object.Posted;
	Items.Organization.ReadOnly = Object.Posted;
	Items.Date.ReadOnly = Object.Posted;
	Items.Number.ReadOnly = Object.Posted;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject) Then
		If TypeOf(BarcodeData_5) = Type("Array") Then
			ArrayOfBarcodes = BarcodeData_5;
		Else
			ArrayOfBarcodes = New Array;
			ArrayOfBarcodes.Add(BarcodeData_5);
		EndIf;
		
		GiftCertificatesClient.ProcessReceivedCodeOnClient(
			ThisObject,
			ArrayOfBarcodes[0].Barcode,
			PredefinedValue("Enum.CardCodeTypes.Barcode"),
			ParametersForProcessingGiftCertificates);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject) Then
		GiftCertificatesClient.ProcessReceivedCodeOnClient(
			ThisObject,
			Data,
			PredefinedValue("Enum.CardCodeTypes.MagneticCode"),
			ParametersForProcessingGiftCertificates);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure SetSelectionParametersForGiftCertificate(Form)
	GiftCertificateSelectionParameters = New Array;
	FilterStructure1 = Form.ParametersForProcessingGiftCertificates.Filters;
	If FilterStructure1.Property("Status") Then
		GiftCertificateSelectionParameters.Add(New ChoiceParameter("Status", FilterStructure1.Status));
	EndIf;
	If FilterStructure1.Property("Organization") Then
		GiftCertificateSelectionParameters.Add(New ChoiceParameter("Organization", FilterStructure1.Organization));
	EndIf;
	Form.Items.GiftCertificatesGiftCertificate.ChoiceParameters = New FixedArray(GiftCertificateSelectionParameters);
EndProcedure

&AtServer
Procedure FillInTablePartGiftCertificates()
	
	SetPrivilegedMode(True);
	
	Object.GiftCertificates.Clear();
		
	CancelPS = Documents.GiftCertificateCancellation.ExpiredGiftCertificatesForDate(
		Object.Organization, 
		New PointInTime(Object.Date, Object.Ref));
	
	For Each Itm In CancelPS Do
		FillPropertyValues(Object.GiftCertificates.Add(), Itm, "GiftCertificate,AmountInCertificateCurrency");
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	GiftCertificateDetails = GiftCertificatesServerCall.GetGiftCertificateDetails(GiftCertificate);
	
	FoundRows = Object.GiftCertificates.FindRows(New Structure("GiftCertificate", GiftCertificate));
	If FoundRows.Count() = 0 Then
		FoundRow = Object.GiftCertificates.Add();
	Else
		FoundRow = FoundRows[0];
	EndIf;
	
	FoundRow.GiftCertificate = GiftCertificate;
	FoundRow.AmountInCertificateCurrency = GiftCertificateDetails.Balance;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion

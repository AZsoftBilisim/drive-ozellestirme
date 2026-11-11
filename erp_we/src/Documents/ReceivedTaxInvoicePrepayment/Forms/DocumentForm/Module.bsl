
#Region Variables

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ReportThatThereIsNoData Then
		CommonClient.MessageToUser(NStr("vi = 'Không tìm thấy dữ liệu để ghi nhận hóa đơn GTGT.';
										|ru = 'Не обнаружены данные для регистрации счета-фактуры.';
										|en = 'Data for registering the tax invoice is not detected.'; fa = 'Data for registering the tax invoice is not detected.';
										|it = 'Non sono stati rilevati dati per la registrazione della fattura.';
										|pl = 'Nie znaleziono danych do rejestracji faktury.';
										|tr = 'Vergi faturası kayıt verileri bulunamadı.'")); 
	EndIf;

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ValueIsFilled(Parameters.Basis) 
		And (TypeOf(Parameters.Basis) = Type("DocumentRef.BankAccountIssue") 
		Or TypeOf(Parameters.Basis) = Type("DocumentRef.CashVoucher")) Then
		
		If Object.Prepayments.Count() = 0 Then
			ReportThatThereIsNoData = True; 
		EndIf; 
	EndIf; 
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	VATAccountingERPInternal.ConfigureJointSelectionOfContractorsOrganizations(Items.Counterparty, Object.Counterparty);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateCreatedOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(Object.Date) Then
		FillInDateOfReceipt_();
	EndIf;
	
EndProcedure

&AtClient
Procedure CorrectionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(Object.Date) Then
		FillInDateOfReceipt_();
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentBasisOnChange(Item)
	
	AvailabilityControl(ThisObject);
	
	If ValueIsFilled(Object.DocumentBasis) Then
		TheseGrounds = GetBaseDataOnServer(Object.DocumentBasis);
		
		FillPropertyValues(Object, TheseGrounds);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If Object.Counterparty = Undefined Then
		Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	EndIf;
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure PatchOnChange(Item)
	
	If Not Object.Patch Then
		
		Object.Number = "";
		Object.CorrectionNumber = "";
		
		ClearFoundationDocuments();
		
	Else
		
		UpdateInformationOnInvoiceBasis();
		
	EndIf;
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure TextInvoiceBaseURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "OpenOriginalInvoices" Then
		StandardProcessing = False;
		OpenInvoice();
	ElsIf  Var_URL = "BaseInvoiceSelection" Then
		StandardProcessing = False;
		InvoiceSelection();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrepayments

&AtClient
Procedure PrepaymentsSumOnChange(Item)
	
	CurrentRow = Items.Prepayments.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure PrepaymentsVATRateOnChange(Item)

	CurrentRow = Items.Prepayments.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		 "PrepaymentsVATRate", "PrepaymentsVATAmount", "PrepaymentsVATAmount");
	
	//
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	AvailabilityControl(ThisObject);
	
	ThereIsEditRight = AccessRight("Update", Metadata.Documents.ReceivedTaxInvoicePrepayment);
	UpdateInformationOnInvoiceBasis();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	BasisType = TypeOf(Object.DocumentBasis);
	
	AvailabilityOfCounterpartyField = (BasisType = Type("DocumentRef.OBEntry")
								Or BasisType = Type("DocumentRef.OBEntryARAP")
								Or BasisType = Type("DocumentRef.ExpenseReport")
								Or BasisType = Type("DocumentRef.ARAPSettlement"));
	
	Items.Counterparty.Enabled = AvailabilityOfCounterpartyField;
	
	CounterpartyTypeCounterparty = TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties");
	
	Items.TINOfCounterparty.Enabled = CounterpartyTypeCounterparty 
	                                       And ValueIsFilled(Object.Counterparty);
	
	Items.GroupNumberDateOfCorrection.Visible = Object.Patch;
	Items.GroupNumberCorrectionDate.Visible = Object.Patch;
	Items.NumberDateGroup.Visible = Not Object.Patch;
	
EndProcedure

&AtServerNoContext
Function GetBaseDataOnServer(DocumentBasis)
	
	TheseGrounds = New Structure;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		
		AttributesValues = Common.ObjectAttributesValues(DocumentBasis, "Counterparty,ARAPAccountingViaSeparateCounterparty,CompanyRecipient");
		If AttributesValues.ARAPAccountingViaSeparateCounterparty Then
			Counterparty = AttributesValues.Counterparty;
		Else
			Counterparty = AttributesValues.CompanyRecipient;
		EndIf; 
		TheseGrounds.Insert("Counterparty", Counterparty);
		
	ElsIf TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntry")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntryARAP")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ExpenseReport")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ARAPSettlement") Then
		
		TheseGrounds.Insert("Counterparty", IncomeAndExpensesServer.GetCounterpartyFromBase(DocumentBasis));
	EndIf;
	
	Return TheseGrounds;

EndFunction

&AtClientAtServerNoContext
Function RecalculationOfAmountOfNDSVToTS(Object, PriceIncludesVAT = True)

	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("PriceIncludesVAT", PriceIncludesVAT);
	
	Return PriceFillingStructure;

EndFunction

&AtClient
Procedure OpenInvoice()
	
	ShowValue(, Object.BaseDocumentTaxInvoice);
	
EndProcedure

&AtClient
Procedure InvoiceSelection(ChoosingBase = True, RowsArray = Undefined)
	
	ParametersStructure = New Structure;
	
	FilterValue = New Structure;
	FilterValue.Insert("DeletionMark", False);
	FilterValue.Insert("Posted", True);
	If ChoosingBase Then
		FilterValue.Insert("Patch", False);
	Else
		If ValueIsFilled(Object.Counterparty) Then
			FilterValue.Insert("Counterparty", Object.Counterparty)
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		FilterValue.Insert("ExcludeInvoice_", Object.Ref);
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		FilterValue.Insert("Organization", Object.Organization)
	EndIf;
	
	ParametersStructure.Insert("Filter", FilterValue);
	
	AdditionalParameters = New Structure("ChoosingBase,RowsArray", ChoosingBase, RowsArray);
	Notification = New CallbackDescription("InvoiceSelectionCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Document.ReceivedTaxInvoicePrepayment.ChoiceForm",
		ParametersStructure,
		ThisObject, , , ,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InvoiceSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		If AdditionalParameters.ChoosingBase Then
			Object.BaseDocumentTaxInvoice = Result;
			FillInBasedOnInvoice();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearFoundationDocuments()
	
	Object.BaseDocumentTaxInvoice = Undefined;
	
	UpdateInformationOnInvoiceBasis();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnInvoiceBasis()
	
	RowsArray = New Array;
	
	If Object.Patch And ValueIsFilled(Object.BaseDocumentTaxInvoice) Then
		
		SFDetails = Common.ObjectAttributesValues(Object.BaseDocumentTaxInvoice, "Number, Date");
		BaseDocumentTaxInvoicePresentation = Documents.ReceivedTaxInvoicePrepayment.InvoicePresentation_(TrimAll(SFDetails.Number), SFDetails.Date);
		
		RowsArray.Add(New FormattedString(
			BaseDocumentTaxInvoicePresentation, ,
			StyleColors.HyperlinkColor, ,
			GetURL(Object.BaseDocumentTaxInvoice)));
			
	EndIf;
	
	If ThereIsEditRight And Object.Patch Then
		
		If ValueIsFilled(Object.BaseDocumentTaxInvoice) Then
			
			RowsArray.Add("   ");
			
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Thay đổi';
					|ru = 'Изменить';
					|en = 'Change'; fa = 'تغییر';
					|it = 'Modificare';
					|pl = 'Change';
					|tr = 'Değiştir'"), ,
				StyleColors.HyperlinkColor, ,
				"BaseInvoiceSelection"));
			
		Else
			
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Chưa chọn hóa đơn GTGT';
					|ru = 'Не выбран счет-фактура';
					|en = 'Tax invoice is not selected'; fa = 'Tax invoice is not selected';
					|it = 'Fattura non selezionata';
					|pl = 'Nie wybrano faktury';
					|tr = 'Vergi faturası seçilmedi'"), ,
				WebColors.FireBrick, ,
				"BaseInvoiceSelection"));
				
		EndIf;
		
	EndIf;
	
	TextInvoiceBase = New FormattedString(RowsArray)
	
EndProcedure

&AtServer
Procedure FillInBasedOnInvoice()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInCorrectionOnInvoice();
	ValueToFormAttribute(DocumentObject, "Object");
	UpdateInformationOnInvoiceBasis();
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDateOfReceipt_()
	
	If Object.Patch And ValueIsFilled(Object.CorrectionDate) Then
		Object.Date = Object.CorrectionDate;
	ElsIf ValueIsFilled(Object.DateCreated) Then
		Object.Date = Object.DateCreated;
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_DateCreated" Then
		DateCreatedOnChange(Items.DateCreated);
	ElsIf Item.Name = "sh_ShamsiInput_CorrectionDate" Then
		CorrectionDateOnChange(Items.CorrectionDate);
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

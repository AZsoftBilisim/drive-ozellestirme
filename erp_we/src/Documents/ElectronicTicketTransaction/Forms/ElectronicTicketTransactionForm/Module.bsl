
#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	WhenCreatingFullReturn(Cancel, Parameters.Basis);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Return of the form for analysis
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	DetailsOfEnteringFine = Documents.ElectronicTicketTransaction.DetailsOfEnteringFine();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	InitializeCompositionOfOperation();
	
	CallbackOnCompletion = New CallbackDescription("EndOfTaskProcessing", ThisObject);
	ClientNotifications.AttachHandler("UpdateFormOfOperationWithElectronicTicket", CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	ForceCloseTheForm = True;
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// It is allowed to skip checking the ban date of operations to add new ones to the document
	If Object.Posted And WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		CurrentObject.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	
	Notify("Record_TicketsAndReservations", WriteParameters, Object.Ref);
	
	WriteParameters.Insert("ElectronicTicket", Object.ElectronicTicket);
	Notify("Write_ElectronicTicketOperation", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ProcessingVerificationOfCompositionOfOperations(Cancel);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CompositionLines =
		Object.Operations.FindRows(New Structure("OperationType", Object.OperationType));
	For Each CompositionRow In CompositionLines Do
		CompositionRow.Date = Object.Date;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.OperationsPenaltyAmount
		And Object.OperationType = PredefinedValue("Enum.TypesOfTicketOperations.Return") Then
		EditAdjustment(RowSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsSumOnChange(Item)
	CalculateVAT();
EndProcedure

&AtClient
Procedure OperationsVATRateOnChange(Item)
	CalculateVAT();
EndProcedure

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not Copy Then
	
		Cancel = True;
		NewOperation = Object.Operations.Add();
		NewOperation.Date = Object.Date;
		NewOperation.OperationType = Object.OperationType;
		NewOperation.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMark_(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure


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

#EndRegion

#Region Private

&AtClient
Procedure EndOfTaskProcessing(MessageData, AdditionalParameters = Undefined) Export
	
	If MessageData.ProcessedDocument = Object.Ref Then
		Read();
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenCreatingFullReturn(Cancel, Basis)
	
	If TypeOf(Basis) = Type("Structure")
		And Basis.Property("DataForCreatingTicketOperation")
		And Parameters.Basis.DataForCreatingTicketOperation.OperationDescription.ThisIsFullReturn
		And Not Object.Operations.Count() Then
		Cancel = True;
		Raise NStr("vi = 'Đã hoàn trả đầy đủ việc mua hàng.';
					|ru = 'Покупка уже полностью возвращена.';
					|en = 'The purchase is fully refunded.'; fa = 'The purchase is fully refunded.';
					|it = 'Покупка уже полностью возвращена.';
					|pl = 'The purchase is fully refunded.';
					|tr = 'Satış hali hazırda tamamen döndürüldü.'");
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingVerificationOfCompositionOfOperations(Cancel)
		
	If Object.Date < BegOfDay(Object.TicketDate) Then
		
		If Object.OperationType = Enums.TypesOfTicketOperations.ExtraPay Then
			ErrorText = NStr("vi = 'Không thể nhập trả trước sớm hơn ngày mua hàng.';
							|ru = 'Нельзя ввести доплату раньше даты покупки.';
							|en = 'Cannot enter the extra pay earlier than the purchase date.'; fa = 'Cannot enter the extra pay earlier than the purchase date.';
							|it = 'Нельзя ввести доплату раньше даты покупки.';
							|pl = 'Cannot enter the extra pay earlier than the purchase date.';
							|tr = 'Satın alma tarihinden önce ek ödeme girilemez.'");
		Else
			ErrorText = NStr("vi = 'Không thể nhập trả lại trước ngày mua hàng.';
							|ru = 'Нельзя ввести возврат раньше даты покупки.';
							|en = 'Cannot enter the return earlier than the purchase date.'; fa = 'Cannot enter the return earlier than the purchase date.';
							|it = 'Нельзя ввести возврат раньше даты покупки.';
							|pl = 'Cannot enter the return earlier than the purchase date.';
							|tr = 'Satın alma tarihinden önce iade girilemez.'");
		EndIf;
		Common.MessageToUser(ErrorText,, "Date", "Object", Cancel);
		
	EndIf;
		
	If Object.OperationType = Enums.TypesOfTicketOperations.Return Then
			
		Ticket_Operations = Documents.ElectronicTicketTransaction.ElectronicTicketOperations(Object.ElectronicTicket,, Object.Ref, True);
		ActiveTicketOperations = Ticket_Operations.Copy(New Structure("DeletionMark", False));
		ActiveTicketOperations.Sort("Date,OperationProcedure");
		BalancesByBids = New Map;
			
		For Each CompositionRow In Object.Operations Do
				
			LinesByVATRate = ActiveTicketOperations.FindRows(New Structure("VATRate", CompositionRow.VATRate));
			SumOfOperations = 0;
			For Each LineOfVATRate In LinesByVATRate Do
				
				If BegOfDay(LineOfVATRate.Date) > BegOfDay(Object.Date) Then
					Continue;
				EndIf;
				
				ThisIsReturn = LineOfVATRate.OperationType = Enums.TypesOfTicketOperations.Return;
				SumOfOperations = SumOfOperations + ?(ThisIsReturn, -LineOfVATRate.Sum, LineOfVATRate.Sum);
				
			EndDo;
				
			BalanceAfterRefund = BalancesByBids.Get(CompositionRow.VATRate);
			If BalanceAfterRefund = Undefined Then
				BalanceAfterRefund = SumOfOperations;
			EndIf;
			BalanceAfterRefund = BalanceAfterRefund - CompositionRow.Sum;
			BalancesByBids.Insert(CompositionRow.VATRate, BalanceAfterRefund);
			
			If BalanceAfterRefund < 0 Then
					
				Field = CommonClientServer.PathToTabularSection("Operations", CompositionRow.LineNumber, "Sum");
					
				MessageText = StrTemplate(
					NStr("vi = 'Số tiền hoàn trả từ %1 theo thuế suất thuế GTGT ""%2""
						|vượt quá số tiền các giao dịch mua trước đó là %3 %4';
						|ru = 'Сумма возврата от %1 по ставке НДС ""%2""
						|превышает сумму ранее совершенных покупок на %3 %4';
						|en = 'The refund amount from %1 at the ""%2"" VAT rate
						|exceeds the amount of previously made purchases by %3 %4'; fa = 'The refund amount from %1 at the ""%2"" VAT rate
						|exceeds the amount of previously made purchases by %3 %4';
						|it = 'The refund amount from %1 at the ""%2"" VAT rate
						|exceeds the amount of previously made purchases by %3 %4';
						|pl = 'The refund amount from %1 at the ""%2"" VAT rate
						|exceeds the amount of previously made purchases by %3 %4';
						|tr = 'KDV oranı, ""%2"" 
						|üzerinden %1 değerinden yapılan iade tutarı, daha önceki alımların tutarlarını %3 %4 oranında aşmaktadır'"),
						Format(Object.Date, "DLF=D"),
						CompositionRow.VATRate,
						-BalanceAfterRefund,
						Object.Currency);
						
				Common.MessageToUser(MessageText, Object.Ref, Field, "Object", Cancel);
					
			EndIf;
			
		EndDo;
		
	EndIf;
		
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	RefreshFormTitle();
	UpdateETicketInformation();
	
	FormFieldSettings = Documents.ElectronicTicketTransaction.SettingsOfFormFieldsForTicketOperations();
	ValueToFormAttribute(FormFieldSettings, "FieldSettings");
	DependenciesOfFormFields = CashServer.DependenciesOfFormFields(FormFieldSettings);
	ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");
	
	CashClientServer.CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure InitializeCompositionOfOperation()
	
	If Not Object.Operations.Count() Then
		NewRow = Object.Operations.Add();
		NewRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
		NewRow.OperationType = Object.OperationType;
		NewRow.Date = Object.Date;
		Items.Operations.CurrentRow = NewRow.GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If ValueIsFilled(Object.Ref) Then
		Template = NStr("vi = '%1 theo vé điện tử %2 %3 ngày %4';
						|ru = '%1 по электронному билету %2 %3 от %4';
						|en = '%1 by electronic ticket %2 %3 dated %4'; fa = '%1 by electronic ticket %2 %3 dated %4';
						|it = '%1 by electronic ticket %2 %3 dated %4';
						|pl = '%1 by electronic ticket %2 %3 dated %4';
						|tr = '%4 tarihli,  %2 %3numaralı elektronik bilet için %1'");
		Title = StrTemplate(
			Template,
			String(Object.OperationType),
			String(Object.ServiceType),
			Object.TicketNumber,
			Object.TicketDate);
	Else
		Template = NStr("vi = '%1 (tạo mới)';
						|ru = '%1 (создание)';
						|en = '%1 (Create)'; fa = '%1 (Create)';
						|it = '%1 (creazione)';
						|pl = '%1 (utworzenie)';
						|tr = '%1 (oluştur)'");
		Title = StrTemplate(Template, Object.OperationType);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateETicketInformation()
	
	ETicketFullNameOfPassenger =
		Common.ObjectAttributeValue(Object.ElectronicTicket, "PassengerSFullName");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// VATAmount
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	ItemField = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.OperationsVATAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Operations.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	RatesWithoutVAT = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RatesWithoutVAT.Add(Catalogs.VATRates.EmptyRef());
	
	ItemFilter.RightValue = RatesWithoutVAT;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
		
	// The amount of the penalty in the table of operations
	Item = ConditionalAppearance.Items.Add();
	
	Fields              = Item.Fields.Items;
	ItemField      = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.OperationsPenaltyAmount.Name);
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.OperationType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTicketOperations.Return;
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Operations.PenaltyAmount");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có tiền phạt';
													|ru = 'Нет штрафа';
													|en = 'No fine'; fa = 'No fine';
													|it = 'Нет штрафа';
													|pl = 'No fine';
													|tr = 'Ceza yok'"));
	
EndProcedure

&AtClient
Procedure EditAdjustment(LineID)
	
	AttributesValues = New Structure(DetailsOfEnteringFine);
	AdjustmentLine = Object.Operations.FindByID(LineID);
	If AdjustmentLine = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(AttributesValues, AdjustmentLine);
	AttributesValues.Insert("Organization", Object.Organization);
	AttributesValues.OperationType = Object.OperationType;
	AttributesValues.Date = Object.Date;
	
	AddlParameters = New Structure("LineID", LineID);
	
	InputFormParameters = New Structure;
	InputFormParameters.Insert("AttributesValues", AttributesValues);
	InputFormParameters.Insert("AttributesOfAdjustingEntries", DetailsOfEnteringFine);
	
	OpenForm("Document.ElectronicTicketTransaction.Form.AdjustmentEntry",
		InputFormParameters,
		,,,,
		New CallbackDescription("AfterEnteringAdjustment", ThisObject, AddlParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
	
&AtClient
Procedure AfterEnteringAdjustment(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	AdjustmentLine = Object.Operations.FindByID(AdditionalParameters.LineID);
	If AdjustmentLine <> Undefined Then
		FillPropertyValues(AdjustmentLine, Result,, "Date,OperationType");
	EndIf;
	Modified = True;
	
EndProcedure

&AtClient
Procedure CalculateVAT()
	
	CurrentRow = Items.Operations.CurrentData;
	
	If Not ValueIsFilled(CurrentRow.VATRate) Then
		CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;
	
	RowData = New Structure;
	RowData.Insert("VATRate", CurrentRow.VATRate);
	RowData.Insert("VATAmount", CurrentRow.VATAmount);
	RowData.Insert("Sum", CurrentRow.Sum);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartClient.ProcessTSString(RowData, StructureOfActions, CachedValues);
	
	CurrentRow.VATAmount = RowData.VATAmount;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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

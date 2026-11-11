
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetParametersForSelectingElementsOfTablePartGiftCertificates(ThisObject);
	
	ChangeVisibilityOfElements();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Items.GroupEnterBalanceBy.Visible = GetFunctionalOption("UseLocal");
	
	SetTitleOfThisForm();
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetTitleOfThisForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GiftCertificateKindOnChange(Item)
	
	TypeOfGiftCertificateWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	ChangeVisibilityOfElements();
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	ChangeVisibilityOfElements();
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	ChangeVisibilityOfElements();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
EndProcedure


#EndRegion

#Region FormTableItemsEventHandlersGiftCertificates

&AtClient
Procedure GiftCertificatesGiftCertificateOnChange(Item)
	
	CurrentData = Items.GiftCertificates.CurrentData;
	
	If Not ValueIsFilled(CurrentData.GiftCertificate) Then
		Return;
	EndIf;
	
	Data = GiftCertificatesServerCall.GetGiftCertificateDetails(CurrentData.GiftCertificate);
	CurrentData.MagneticCode = Data.MagneticCode;
	CurrentData.Barcode = Data.Barcode;
	CurrentData.SerialNumber = Data.SerialNumber;
	
	FillInAmounts(
		CurrentData.AmountInCertificateCurrency,
		CurrentData.SumCompl,
		CurrentData.SumMan,
		Object.GiftCertificateKind);
	
EndProcedure

&AtClient
Procedure GiftCertificatesAmountInCertificateCurrencyOnChange(Item)
	
	CurrentData = Items.GiftCertificates.CurrentData;
	
	FillInAmounts(
		CurrentData.AmountInCertificateCurrency,
		CurrentData.SumCompl,
		CurrentData.SumMan,
		Object.GiftCertificateKind);
	
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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiftCertificatesSerialNumber.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiftCertificatesBarcode.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiftCertificatesMagneticCode.Name);

	DataCompositionClientServer.AddFilter(Item.Filter, "Object.GiftCertificates.GiftCertificate", Undefined, DataCompositionComparisonType.Filled);
	
	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServer
Procedure ChangeVisibilityOfElements()
	
	AttributesValues = Common.ObjectAttributesValues(Object.GiftCertificateKind, "CardType");
	If AttributesValues.CardType = Enums.CardTypes.Magnetic Then
		Items.GiftCertificatesMagneticCode.Visible = True;
		Items.GiftCertificatesBarcode.Visible     = False;
	ElsIf AttributesValues.CardType = Enums.CardTypes.Barcode_ Then
		Items.GiftCertificatesMagneticCode.Visible = False;
		Items.GiftCertificatesBarcode.Visible     = True;
	Else
		Items.GiftCertificatesMagneticCode.Visible = True;
		Items.GiftCertificatesBarcode.Visible     = True;
	EndIf;
	
	Items.GiftCertificatesSumCompl.Visible = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
	Items.GiftCertificatesSumMan.Visible = Object.RecordInOperationalAccounting Or Object.RecordInMA;
	
EndProcedure

&AtServer
Procedure TypeOfGiftCertificateWhenChangedOnServer()
	
	ChangeVisibilityOfElements();
	
	For Each TSRow In Object.GiftCertificates Do
		TSRow.GiftCertificate = Undefined;
	EndDo;
	
	SetParametersForSelectingElementsOfTablePartGiftCertificates(ThisObject);
	
EndProcedure

&AtServer
Function FillInAmounts(Sum, SumCompl, SumMan, GiftCertificateKind)
	
	DocumentDate = Object.Date;
	
	If ValueIsFilled(GiftCertificateKind) Then
		
		Currency = Common.ObjectAttributeValue(GiftCertificateKind, "Currency");
		
		If Currency = LocalAccountingCurrency Then
			SumCompl = Sum;
		Else
			ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, LocalAccountingCurrency, DocumentDate);
			SumCompl = Round(Sum * ConversionFactor_, 2, 1);
		EndIf;
		
		If Currency = ManagementAccountingCurrency Then
			SumMan = Sum;
		Else
			ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, ManagementAccountingCurrency, DocumentDate);
			SumMan = Round(Sum * ConversionFactor_, 2, 1);
		EndIf;
		
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetParametersForSelectingElementsOfTablePartGiftCertificates(Form)

	NameOfSelectionParameter = "Filter.Owner";
	ChoiceParametersArray = New Array(Form.Items.GiftCertificatesGiftCertificate.ChoiceParameters);
	ThereIsSelectionByOwner = False;
	For Each ArrayElement In ChoiceParametersArray Do // ChoiceParameter
		If ArrayElement.Name = NameOfSelectionParameter Then
			ThereIsSelectionByOwner = True;
			Break;
		EndIf;
	EndDo;
	SelectionParameterSelectionByOwner = New ChoiceParameter(NameOfSelectionParameter, Form.Object.GiftCertificateKind);
	If ThereIsSelectionByOwner Then
		ChoiceParametersArray[ChoiceParametersArray.Find(ArrayElement)] = SelectionParameterSelectionByOwner;
	Else
		ChoiceParametersArray.Add(SelectionParameterSelectionByOwner);	
	EndIf;
	
	Form.Items.GiftCertificatesGiftCertificate.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

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

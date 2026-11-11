
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetDefaultValues();
	SetValuesForFormParameters(Parameters);
	UpdateFormData();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ArrayOfManagersSeeAlsoWorkplace = New Array();
	ReceivedTaxInvoicePrepaymentLocalization.FillInManagersSeeAlsoWorkplace(ArrayOfManagersSeeAlsoWorkplace);
	If ArrayOfManagersSeeAlsoWorkplace.Count() = 0 Then
		ArrayOfManagersSeeAlsoWorkplace.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName());
	EndIf;
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayOfManagersSeeAlsoWorkplace, Undefined);
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");

	VATAccountingERPInternal.ConfigureJointSelectionOfContractorsOrganizations(Items.FilterVendor, FilterVendor);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetVisibilityOfCommands();
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	UpdateFormData();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	KeyOperationName = StrTemplate("DataProcessor.ReceivedTaxInvoicePrepayment.Form.WorkplaceForm.SeeAlso.%1",
									FormattedStringURL);
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	
	If ValueIsFilled(Organization) Then
		QuickFilterStructure.Insert("Organization", Organization);
		FormParameters.Insert("Organization", Organization);
	EndIf;
	
	If ValueIsFilled(FilterVendor) Then
		QuickFilterStructure.Insert("Counterparty", FilterVendor);
	EndIf;
	
	CurrentDate = CommonClient.SessionDate();
	Period = New StandardPeriod;
	Period.StartDate = BeginOfPeriod;
	Period.EndDate = EndOfPeriod;
	QuickFilterStructure.Insert("Period", Period);
	QuickFilterStructure.Insert("BeginOfPeriod", ?(ValueIsFilled(Period.StartDate), Period.StartDate, BegOfQuarter(CurrentDate)));
	FormParameters.Insert("BeginOfPeriod", QuickFilterStructure.BeginOfPeriod);
	QuickFilterStructure.Insert("EndOfPeriod", ?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfQuarter(CurrentDate)));
	FormParameters.Insert("EndOfPeriod", QuickFilterStructure.EndOfPeriod);
	
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, FormParameters,ThisForm, ThisForm.UUID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrepaymentsToVendor_

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetStateSelection(Items.TableAdvancesPaid, FilterState, FilterVendor);
	
EndProcedure

&AtClient
Procedure FilterVendorOnChange(Item)
	
	If FilterVendor = Undefined Then
		FilterVendor = CommonClientServer.PredefinedItem("Catalog.Counterparties.EmptyRef");
	EndIf;
	
	If Not ValueIsFilled(FilterVendor) Then
		Items.TableAdvancesPaid.RowFilter = Undefined
	Else	
		Items.TableAdvancesPaid.RowFilter = New FixedStructure("Vendor",FilterVendor);
		FilterState = "AllPaidAdvances";
	EndIf;
	
EndProcedure

&AtClient
Procedure OutstandingAdvancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Parent = Items.GroupPaymentDocumentDetails Then
		OpenPaymentDocumentAdvance();
	Else
		EnterTheInvoiceReceivedAdvancePayment();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectPeriod(Command)
	
	ChoiceParameters = New Structure("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, EndOfPeriod);
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	OpenForm("CommonForm.SelectAStandardPeriod", ChoiceParameters, Items.SelectPeriod, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure EnterTheInvoiceReceivedAdvancePaymentExecute(Command)
	
	EnterTheInvoiceReceivedAdvancePayment();
	
EndProcedure

&AtClient
Procedure OpenPaymentDocumentAdvanceExecute(Command)
	
	OpenPaymentDocumentAdvance();
	
EndProcedure

&AtClient
Procedure FillInAdvances(Command)
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure UpdateCalculations(Command)
	
	CallbackDescription = New CallbackDescription("UpdateCalculationsCompletion", ThisObject);
	ShowQueryBox(
		CallbackDescription, 
		NStr("vi = 'Cập nhật hạch toán với nhà cung cấp?';
			|ru = 'Актуализировать расчеты с поставщиками?';
			|en = 'Update vendor AR/AP?'; fa = 'Update vendor AR/AP?';
			|it = 'Aggiornare pagamenti ai fornitori?';
			|pl = 'Chcesz zaktualizować rozliczenia z klientami?';
			|tr = 'Tedarikçi mutabakatı güncellensin mi?'"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure UpdateCalculationsCompletion(QuestionResult, AdditionalParameters) Export
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		
		UpdateCalculationsServer();
		ShowUserNotification(
			NStr("vi = 'Đã cập nhật hạch toán';
				|ru = 'Расчеты актуализированы';
				|en = 'Settlements are updated'; fa = 'Settlements are updated';
				|it = 'Pagamenti aggiornati';
				|pl = 'Rozliczenia są zaktualizowane';
				|tr = 'Mutabakatlar güncellendi'"),
			, // URL
			NStr("vi = 'Đã cập nhật hạch toán với nhà cung cấp';
				|ru = 'Расчеты с поставщиками актуализированы';
				|en = 'Vendor AR/AP are updated'; fa = 'Vendor AR/AP are updated';
				|it = 'Pagamenti a fornitori aggiornati';
				|pl = 'Rozliczenia z dostawcami zaktualizowano';
				|tr = 'Tedarikçi mutabakatı güncellendi'"));
			
		RelevanceOfCalculationLimit = True;
		Items.GroupRelevanceOfCalculations.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.TableAdvancesPaid);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.TableAdvancesPaid, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.TableAdvancesPaid);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region GettingFormData

&AtServer
Procedure FillOutAdvancesIssued()
	
	AdditionalParameters = Documents.ReceivedTaxInvoicePrepayment.AdditionalParametersOfAdvancesIssued();
	AdditionalParameters.ExcludeJUDAS = True;
	AdditionalParameters.InContextOfNP = False;
	
	Result = Documents.ReceivedTaxInvoicePrepayment.ReceiveAdvancesIssued(Organization, BeginOfPeriod, EndOfPeriod, AdditionalParameters);
	
	PrepaymentsToVendor_.Load(Result);
	
	For Each String In PrepaymentsToVendor_ Do
		If String.TaxInvoice <> Documents.ReceivedTaxInvoicePrepayment.EmptyRef()
				And String.AmountOfSchedAdvance <> String.TaxInvoiceAmount
				And Not String.Patch Then
			String.SumError = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region PrepaymentsToVendor

&AtServer
Procedure UpdateLineDataForAdvancesIssued(DocumentBasis, Vendor)
	
	InvoiceDetails = New Structure;
	InvoiceDetails.Insert("TaxInvoiceNumber", "");
	InvoiceDetails.Insert("TaxInvoiceDate",  '00010101');
	InvoiceDetails.Insert("TaxInvoiceAmount", 0);
	InvoiceDetails.Insert("TaxInvoice",       Undefined);
	
	// We will get the invoice data
	Query = New Query;
	
	QueryText = 
	"SELECT ALLOWED
	|	ReceivedTaxInvoicePrepayment.Ref          AS TaxInvoice,
	|	ReceivedTaxInvoicePrepayment.Number           AS TaxInvoiceNumber,
	|	ReceivedTaxInvoicePrepayment.DateCreated AS TaxInvoiceDate,
	|	ReceivedTaxInvoicePrepayment.Sum           AS TaxInvoiceAmount
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS ReceivedTaxInvoicePrepayment
	|	LEFT JOIN 
	|		Document.ReceivedTaxInvoicePrepayment AS InvoiceReceivedCorrection
	|	ON 
	|		ReceivedTaxInvoicePrepayment.DocumentBasis = InvoiceReceivedCorrection.DocumentBasis
	|		AND (CASE
	|				WHEN VALUETYPE(ReceivedTaxInvoicePrepayment.DocumentBasis) = TYPE(Document.OBEntry) THEN
	|					ReceivedTaxInvoicePrepayment.Counterparty= InvoiceReceivedCorrection.Counterparty
	|				ELSE TRUE
	|			END)
	|		AND ReceivedTaxInvoicePrepayment.Ref = InvoiceReceivedCorrection.BaseDocumentTaxInvoice
	|		AND InvoiceReceivedCorrection.Patch
	|		AND InvoiceReceivedCorrection.Posted
	|WHERE
	|	ReceivedTaxInvoicePrepayment.DocumentBasis = &DocumentBasis
	|	AND (CASE
	|			WHEN VALUETYPE(ReceivedTaxInvoicePrepayment.DocumentBasis) = TYPE(Document.OBEntry)
	|				THEN ReceivedTaxInvoicePrepayment.Counterparty = &Vendor
	|			ELSE TRUE
	|		END)
	|	AND NOT ReceivedTaxInvoicePrepayment.Patch
	|	AND ReceivedTaxInvoicePrepayment.Posted
	|	AND InvoiceReceivedCorrection.Ref IS NULL";
	 
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("Vendor",        Vendor);
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(InvoiceDetails, Selection);
	EndIf; 
	
	// The advance can be in different currencies, in this case there will be several lines
	ListOfAdvances = PrepaymentsToVendor_.FindRows(New Structure("DocumentBasis, Vendor", DocumentBasis, Vendor));
	For Each AlCollections In ListOfAdvances Do
		FillPropertyValues(AlCollections, InvoiceDetails);
	EndDo; 
	
EndProcedure

&AtClient
Procedure EnterTheInvoiceReceivedAdvancePayment()

	CurrentData = Items.TableAdvancesPaid.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.TaxInvoice.IsEmpty() Then
		
		ClearMessages();
	
		If Not ValueIsFilled(Organization) And UseMultipleCompanies Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn doanh nghiệp';
													|ru = 'Выберите организацию';
													|en = 'Select company'; fa = 'Select company';
													|it = 'Selezionare società';
													|pl = 'Wybierz firmę';
													|tr = 'İş yeri seç'"), , "Organization");
			Return;
		EndIf;
		
		BaseStructure = New Structure;
		BaseStructure.Insert("Organization",       Organization);
		BaseStructure.Insert("DocumentBasis", CurrentData.DocumentBasis);
		BaseStructure.Insert("VATTaxation", CurrentData.VATTaxation);
		BaseStructure.Insert("Counterparty",        CurrentData.Vendor);
		BaseStructure.Insert("Currency",            CurrencyOfComplianceAccounting);
		BaseStructure.Insert("Date",              CurrentData.Date);
		BaseStructure.Insert("Sum",             CurrentData.AmountOfSchedAdvance);
		
		FormParameters = New Structure("Basis", BaseStructure);
	Else
		FormParameters = New Structure("Key", CurrentData.TaxInvoice);
	EndIf; 
	
	CallbackDescription = New CallbackDescription("EnterTheInvoiceReceivedAdvancePaymentCompletion", ThisObject, New Structure("CurrentData", CurrentData));
	OpenForm("Document.ReceivedTaxInvoicePrepayment.ObjectForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure EnterTheInvoiceReceivedAdvancePaymentCompletion(Result, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	UpdateLineDataForAdvancesIssued(CurrentData.DocumentBasis, CurrentData.Vendor);
	
EndProcedure

&AtClient
Procedure OpenPaymentDocumentAdvance()

	CurrentData = Items.TableAdvancesPaid.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	TableName = TableNameByRef(CurrentData.DocumentBasis);
	
	OpenForm(TableName + ".ObjectForm", New Structure("Key", CurrentData.DocumentBasis));
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(ThisForm, SelectionResult, "BeginOfPeriod,EndOfPeriod");
	
	UpdateFormData();
	
EndProcedure

&AtServer
Function TableNameByRef(Ref)
	
	Return Common.TableNameByRef(Ref);
	
EndFunction

&AtServer
Procedure SetDefaultValues()

	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	BeginOfPeriod = BegOfQuarter(CurrentSessionDate());
	EndOfPeriod = EndOfQuarter(CurrentSessionDate());
	
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	EstablishRelevanceOfCalculationBoundary();
	
	FillOutAdvancesIssued();
	
	SetStateSelection(Items.TableAdvancesPaid, FilterState, FilterVendor);

	If ValueIsFilled(CurrencyOfComplianceAccounting) Then 
		Items.TableIssuedAdvancesAmountOfAdvanceRegl.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số tiền ứng trước (%1)';
																															|ru = 'Сумма аванса (%1)';
																															|en = 'Prepayment amount (%1)'; fa = 'Prepayment amount (%1)';
																															|it = 'Сумма аванса (%1)';
																															|pl = 'Prepayment amount (%1)';
																															|tr = 'Ön ödeme tutarı (%1)'"), CurrencyOfComplianceAccounting);
	Else
		Items.TableIssuedAdvancesAmountOfAdvanceRegl.Title = NStr("vi = 'Số tiền ứng trước (pháp quy)';
																	|ru = 'Сумма аванса (регл.)';
																	|en = 'Prepayment amount (local)'; fa = 'مبلغ پیش‌پرداخت (محلی)';
																	|it = 'Сумма аванса (регл.)';
																	|pl = 'Prepayment amount (local)';
																	|tr = 'Ön ödeme tutarı (yerel)'");
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishRelevanceOfCalculationBoundary()
	
	CalculationPeriod = EndOfMonth(EndOfPeriod);
	
	FilterFields = New Structure("Organization, Partner, Counterparty, Contract");
	FilterFields.Organization = Organization;
	CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
	CalculationAnalysts.AccountingAnalyticsForPartners = ARAPAllocationServerCall.ArrayOfKeysForSelectionPartners(FilterFields);
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		SetPrivilegedMode(True);
		CalculationStart = InformationRegisters.JobsForARAPAllocating.CurrentPeriodOfCalculatedDataOnMutualSettlements(
			CalculationAnalysts.AccountingAnalyticsForPartners, , CalculationPeriod);
		SetPrivilegedMode(False);
		
		If CalculationStart = Undefined Or CalculationStart > CalculationPeriod Then
			RelevanceOfCalculationLimit = True;
		Else
			RelevanceOfCalculationLimit = False;
		EndIf;
		Items.GroupRelevanceOfCalculations.Visible = Not RelevanceOfCalculationLimit;
	Else
		SetPrivilegedMode(True);
		CalculationStart = ARAPAllocationServerCall.StartOfCalculations(CalculationPeriod, CalculationAnalysts, "VendorsARAPAccounting");
		SetPrivilegedMode(False);
		
		If Not ValueIsFilled(CalculationStart) Or CalculationStart > CalculationPeriod Then
			RelevanceOfCalculationLimit = True;
		Else
			RelevanceOfCalculationLimit = False;
		EndIf;
		Items.GroupRelevanceOfCalculations.Visible = Not RelevanceOfCalculationLimit;
	EndIf
EndProcedure

&AtServer
Procedure UpdateCalculationsServer()
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		FilterFields = New Structure;
		FilterFields.Insert("Organization", Organization);
		FilterFields.Insert("Partner", Undefined);
		FilterFields.Insert("Counterparty", Undefined);
		FilterFields.Insert("Contract", Undefined);
		AccountingAnalyticsForPartners = ARAPAllocationServerCall.ArrayOfKeysForSelectionPartners(FilterFields);

		DocumentsForUpdatingMutualSettlements = InformationRegisters.JobsForARAPAllocating.DocumentsForDistributionOfSettlementsByTime(
			AccountingAnalyticsForPartners, , EndOfMonth(EndOfPeriod));
		
		BackdateJobQueue.CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(
			DocumentsForUpdatingMutualSettlements, Catalogs.BackdateJobKinds.ARAPAllocationByDueDates);
		
	Else
		
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(EndOfMonth(EndOfPeriod) + 1, CalculationAnalysts);
		
	EndIf;
	
	FillOutAdvancesIssued();
	
EndProcedure

&AtServer
Procedure SetValuesForFormParameters(Var_Parameters)

	QuickFilterStructure = Undefined;
	Var_Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("BeginOfPeriod", BeginOfPeriod);
		QuickFilterStructure.Property("EndOfPeriod", EndOfPeriod);
		QuickFilterStructure.Property("FilterState", FilterState);
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommands()
	
	If IsInRole("AddEditTaxInvoiceReceivedForAdvance") Or
		 IsInRole("FullAccess") Then
		 	Items.EnterInvoiceCommandPanel.Visible = True;
	Else
		Items.EnterInvoiceCommandPanel.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SetStateSelection(TableAdvancesPaid, FilterState, FilterVendor)

	If FilterState = "InvoiceRegistrationRequired" Then
		TableAdvancesPaid.RowFilter = New FixedStructure("TaxInvoice",PredefinedValue("Document.ReceivedTaxInvoicePrepayment.EmptyRef"));
		FilterVendor = Undefined;
	ElsIf FilterState = "AmountsOfAdvanceAndFSFDiffer" Then
		TableAdvancesPaid.RowFilter = New FixedStructure("SumError", True);
		FilterVendor = Undefined;
	Else
		TableAdvancesPaid.RowFilter = Undefined;
	EndIf;

EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableAdvancesPaid.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsToVendor_.SumError");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", New Color(255, 200, 200));

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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
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

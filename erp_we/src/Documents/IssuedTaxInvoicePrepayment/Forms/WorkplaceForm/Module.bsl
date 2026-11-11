
#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetDefaultValues();
	SetValuesForFormParameters(Parameters);
	SetHeaderUnusedInvoices();
	
	WhenSelectionChanges();
	
	UnusedInvoicesTable.Parameters.SetParameterValue("UnusedTaxInvoices", New Array);
	
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ArrayOfManagersSeeAlsoWorkplace = New Array();
	IssuedTaxInvoicePrepaymentLocalization.FillInManagersSeeAlsoWorkplace(ArrayOfManagersSeeAlsoWorkplace);
	If ArrayOfManagersSeeAlsoWorkplace.Count() = 0 Then
		ArrayOfManagersSeeAlsoWorkplace.Add(Metadata.Documents.IssuedTaxInvoicePrepayment.FullName());
	EndIf;
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayOfManagersSeeAlsoWorkplace, Undefined);

	If Parameters.Property("FillInWhenOpening") Then
		FillInReceivedAdvancesOnServer(); 
		SetStateSelection(Items.PrepaymentsFromCustomerLayout, FilterState);
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetVisibilityOfCommands();
	SetFieldVisibility();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Electronic documents"
	If EventName = "UpdateEdState" Then
		Items.PrepaymentsFromCustomerLayout.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	WhenSelectionChanges();
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetStateSelection(Items.PrepaymentsFromCustomerLayout, FilterState);
	
EndProcedure

&AtClient
Procedure CloseLabelClick(Item)
	
	ShowInformationLabel = False;
	
	UpdateDisplayOfInformationLabel();
	
EndProcedure

&AtClient
Procedure NavigationLinkProcessingLabel(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterState = "PaymentAndSettlementDocumentDataIsMissing";
	SetStateSelection(Items.PrepaymentsFromCustomerLayout, FilterState);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure PrepaymentsFromCustomerLayoutVATRateOnChange(Item)
	
	CurrentRow = Items.PrepaymentsFromCustomerLayout.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure AdvancesReceivedAmountOfTheAdvanceWhenChanged(Item)
	
	CurrentRow = Items.PrepaymentsFromCustomerLayout.CurrentData;
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	CurrentRow.CurrencyAmount = CurrentRow.Sum;
	
	// Check the currency, if it differs from the currency of the accounting, then recalculate the amounts
	DataCurrency = CurrentRow.DocumentCurrency;
	If ValueIsFilled(DataCurrency)
		And DataCurrency <> CurrencyOfComplianceAccounting Then
		
		AdvancesReceivedAmountOfTheAdvanceWhenChangedServer(
			CurrencyOfComplianceAccounting,
			DataCurrency,
			CurrentRow.DocumentBasis,
			CurrentRow.Sum,
			CurrentRow.CurrencyAmount);
	EndIf; 
	
EndProcedure

&AtClient
Procedure PrepaymentsFromCustomerLayoutCurrencyAmountOnChange(Item)
	
	CurrentRow = Items.PrepaymentsFromCustomerLayout.CurrentData;
	
	CurrentRow.Sum = CurrentRow.CurrencyAmount;
	
	// Check the currency, if it differs from the currency of the accounting, then recalculate the amounts
	DataCurrency = CurrentRow.DocumentCurrency;
	If ValueIsFilled(DataCurrency)
		And DataCurrency <> CurrencyOfComplianceAccounting Then
		
		PrepaymentsFromCustomerLayoutCurrencyAmountOnChangeServer(
			CurrencyOfComplianceAccounting,
			DataCurrency,
			CurrentRow.BaseDocumentDate, 
			CurrentRow.CurrencyAmount,
			CurrentRow.Sum);
	EndIf; 

	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure PrepaymentsFromCustomerLayoutSelection(Item, RowSelected, Field, StandardProcessing)
	
	If (Field = Items.PrepaymentsFromCustomerLayoutTaxInvoice Or Field.Parent = Items.ReceivedAdvancesGroupInv) Then
		
		CurInvoice = Item.CurrentData.TaxInvoice;
		If ValueIsFilled(CurInvoice) Then
			StandardProcessing = False;
			ShowValue(Undefined, CurInvoice);
		EndIf;
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure UnusedTaxInvoicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentDocument = Item.CurrentData.TaxInvoice;
	
	If ValueIsFilled(CurrentDocument) Then
		ShowValue(Undefined, CurrentDocument);
	EndIf;
			
EndProcedure

&AtClient
Procedure PrepaymentsFromCustomerLayoutSelectedOnChange(Item)
	
	CurrentDocumentBasis = Items.PrepaymentsFromCustomerLayout.CurrentData.DocumentBasis;
	Selected = Items.PrepaymentsFromCustomerLayout.CurrentData.Selected;
	
	BaseLines = PrepaymentsFromCustomerLayout.FindRows(New Structure("DocumentBasis", CurrentDocumentBasis));
	For Each String In BaseLines Do
		String.Selected = Selected;
	EndDo;
	
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
Procedure FillInReceivedAdvances(Command)
	
	ClearMessages();
	If CheckFilling() Then
		FillInReceivedAdvancesOnServer();
	EndIf; 
	
	SetStateSelection(Items.PrepaymentsFromCustomerLayout, FilterState);
	
EndProcedure

&AtClient
Procedure GenerateInvoices(Command)
	
	CreatingInvoices();
	
EndProcedure

&AtClient
Procedure DeleteUnusedInvoices(Command)
	
	DeleteUnusedInvoicesServer();	
	
EndProcedure

&AtClient
Procedure CreateAnInvoice_3(Command)
	
	AdvancePaymentData = Items.PrepaymentsFromCustomerLayout.CurrentData;
	
	If AdvancePaymentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Cần chọn khoản ứng trước đã nhận!';
										|ru = 'Необходимо выбрать полученный аванс!';
										|en = 'Select the prepayment from customer.'; fa = 'Select the prepayment from customer.';
										|it = 'È necessario selezionare l''anticipo ricevuto!';
										|pl = 'Należy wybrać otrzymaną zaliczkę';
										|tr = 'Alınan avans ödemesinin seçilmesi gerekmektedir!'"));
	Else
		CreatingInvoices(AdvancePaymentData.GetID())
	EndIf;	
	
EndProcedure

&AtClient
Procedure SetVATRate(Command)
	
	FormParameters = ParametersOfVATRateSelectionForm();
	OpenForm("Catalog.VATRates.ChoiceForm", 
		FormParameters,,,,, 
		New CallbackDescription("SetVATRateCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SetEmployeeResponsible(Command)
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("PropsName", "EmployeeResponsible");
	ProcessingParameters.Insert("AttributeType", "Catalog.Users");
	ProcessingParameters.Insert("ChoiceMode", True);
	
	SetProps(ProcessingParameters);
	
EndProcedure

&AtClient
Procedure SetOperatingUnit(Command)
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("PropsName", "Department");
	ProcessingParameters.Insert("AttributeType", "Catalog.BusinessStructure");
	ProcessingParameters.Insert("Filter", New Structure("Organization", Organization));
	
	SetProps(ProcessingParameters);
	
EndProcedure

&AtClient
Procedure InstallAManager(Command)
	
	FilterStructure1 = New Structure("Owner,EmployeeInCharge_",
		Organization, PredefinedValue("Enum.PersonsResponsibleAndCompanies.Director"));
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("PropsName", "Director");
	ProcessingParameters.Insert("AttributeType", "Catalog.PersonsResponsibleAndCompanies");
	ProcessingParameters.Insert("Filter", FilterStructure1);
	
	SetProps(ProcessingParameters);
	
EndProcedure

&AtClient
Procedure InstallTheChiefAccountant(Command)
	
	FilterStructure1 = New Structure("Owner,EmployeeInCharge_",
		Organization, PredefinedValue("Enum.PersonsResponsibleAndCompanies.ChiefAccountant"));
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("PropsName", "ChiefAccountant");
	ProcessingParameters.Insert("AttributeType", "Catalog.PersonsResponsibleAndCompanies");
	ProcessingParameters.Insert("Filter", FilterStructure1);
	
	SetProps(ProcessingParameters);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	For Each AdvanceLine_ In PrepaymentsFromCustomerLayout Do
		AdvanceLine_.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure Exclude(Command)
	
	For Each AdvanceLine_ In PrepaymentsFromCustomerLayout Do
		AdvanceLine_.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectMarked(Command)
	
	For Each AdvanceLine_ In Items.PrepaymentsFromCustomerLayout.SelectedRows Do
		Items.PrepaymentsFromCustomerLayout.RowData(AdvanceLine_).Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearMarked(Command)
	
	For Each AdvanceLine_ In Items.PrepaymentsFromCustomerLayout.SelectedRows Do
		Items.PrepaymentsFromCustomerLayout.RowData(AdvanceLine_).Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.PrepaymentsFromCustomerLayout);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.PrepaymentsFromCustomerLayout, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.PrepaymentsFromCustomerLayout);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	KeyOperationName = StrTemplate("DataProcessor.IssuedTaxInvoicePrepayment.Form.WorkplaceForm.SeeAlso.%1",
									FormattedStringURL);
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	
	If ValueIsFilled(Organization) Then
		QuickFilterStructure.Insert("Organization", Organization);
		FormParameters.Insert("Organization", Organization);
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

#Region Private

#Region OnChangeAttributes

&AtServerNoContext
Procedure AdvancesReceivedAmountOfTheAdvanceWhenChangedServer(CurrencyOfComplianceAccounting, DataCurrency, DocumentBasis, Sum, CurrencyAmount)
	
	BaseDocumentDate = Common.ObjectAttributeValue(DocumentBasis, "Date");
	
	LocalCourseStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfComplianceAccounting, BaseDocumentDate, CurrencyOfComplianceAccounting);
	RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(DataCurrency, BaseDocumentDate, CurrencyOfComplianceAccounting);
	CurrencyAmount = ProcessingOfExchangeRatesTM.ConvertAtRate(
		Sum,
		LocalCourseStructure,
		RateStructure);
	
EndProcedure

&AtServerNoContext
Procedure PrepaymentsFromCustomerLayoutCurrencyAmountOnChangeServer(CurrencyOfComplianceAccounting, DataCurrency, BaseDocumentDate, CurrencyAmount, Sum)
	
	LocalCourseStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfComplianceAccounting, BaseDocumentDate, CurrencyOfComplianceAccounting);
	RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(DataCurrency, BaseDocumentDate, CurrencyOfComplianceAccounting);
	Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(
		CurrencyAmount,
		LocalCourseStructure,
		RateStructure);
	
EndProcedure

&AtServer
Procedure WhenSelectionChanges()
	
	EstablishRuleForSelectionOfAdvancesReceived();
	
EndProcedure

#EndRegion

#Region FillingForm

&AtServer
Procedure FillInReceivedAdvancesOnServer()
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		//Updating of settlements with clients
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(EndOfPeriod, CalculationAnalysts);
	Else
		If InformationRegisters.JobsForARAPAllocating.CurrentPeriodOfCalculatedDataOnMutualSettlements() <> Undefined Then
			Common.MessageToUser(ARAPAccountingServer.TextOfWarningOfAssignmentOfDistributionOfMutualSettlements());
		EndIf;
	EndIf;
	
	// We will get a list of invoices
	FillInAdvances();
	
EndProcedure

&AtServer
Function FillInAdvances()
	
	If Not ValueIsFilled(Organization) Then
		Return False;
	EndIf;
	
	SelectionOfAdvances = Documents.IssuedTaxInvoicePrepayment.SelectionOfAdvancesReceived();
	FillPropertyValues(SelectionOfAdvances, ThisObject);
	
	SettlementDocumentsWithoutInvoice = New Array;
	
	PrepaymentsFromCustomerLayout.Clear();
	
	AdvancesReceivedVt = PrepaymentsFromCustomerLayout.Unload();
	Documents.IssuedTaxInvoicePrepayment.FillInReceivedAdvancesForSF(SelectionOfAdvances, AdvancesReceivedVt, SettlementDocumentsWithoutInvoice);
	PrepaymentsFromCustomerLayout.Load(AdvancesReceivedVt);
	PrepaymentsFromCustomerLayout.Sort("DateOfDischarge");
	FillInUnusedInvoices();
	
	AdvancesReceivedVt.GroupBy("DocumentBasis, Sfsformed, Patch, TaxInvoiceAmount", "Sum");
	For Each String In AdvancesReceivedVt Do
		If String.Sfsformed = True
			And String.Sum <> String.TaxInvoiceAmount
			And Not String.Patch = True Then
			SumErrorLines = PrepaymentsFromCustomerLayout.FindRows(New Structure("DocumentBasis", String.DocumentBasis));
			For Each ErrorString In SumErrorLines Do
				ErrorString.SumError = True;
			EndDo;
		EndIf;
	EndDo;
	
	// We will inform the user that there are settlement documents for which it was not possible to generate an invoice.
	For Each AlCollections In SettlementDocumentsWithoutInvoice Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với chứng từ, không xem xét ghi nhận hóa đơn GTGT: %1';
																					|ru = 'Для документа не предусмотрена регистрация счета-фактуры: %1';
																					|en = 'Tax invoice registration is not available for the document: %1'; fa = 'Tax invoice registration is not available for the document: %1';
																					|it = 'Per il documento non prevista la registrazione della fattura: %1';
																					|pl = 'Dla dokumentu nie jest przewidziana rejestracja faktury: %1';
																					|tr = 'Belge için herhangi bir fatura kaydı bulunmamaktadır: %1'"), AlCollections);
		CommonClientServer.MessageToUser(MessageText, AlCollections);
	EndDo; 
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInUnusedInvoices()
	
	UnusedTaxInvoices.Clear();
	
	Query = New Query;
	
	QueryText = "
	|SELECT
	|	IssuedTaxInvoicePrepayment.Ref AS Ref,
	|	IssuedTaxInvoicePrepayment.DocumentBasis,
	|	IssuedTaxInvoicePrepayment.Counterparty
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|WHERE
	|	IssuedTaxInvoicePrepayment.Organization = &Organization
	|	AND IssuedTaxInvoicePrepayment.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND NOT IssuedTaxInvoicePrepayment.DeletionMark
	|	AND IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter <> VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments)
	|	AND NOT IssuedTaxInvoicePrepayment.Patch
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = IssuedTaxInvoicePrepayment.Ref
	|			AND DocumentsRegistry.Posted)
	|";
	 
	Query.Text = QueryText;
	Query.SetParameter("Organization",   Organization);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  EndOfDay(EndOfPeriod));  
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.IssuedTaxInvoicePrepayment"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FilterParameters = New Structure("DocumentBasis,Counterparty", Selection.DocumentBasis, Selection.Counterparty);
		If PrepaymentsFromCustomerLayout.FindRows(FilterParameters).Count() = 0 Then
			UnusedTaxInvoices.Add(Selection.Ref);
		EndIf; 
	EndDo;
	
	UnusedInvoicesTable.Parameters.SetParameterValue("UnusedTaxInvoices", UnusedTaxInvoices.UnloadValues());
	SetHeaderUnusedInvoices();
	
EndProcedure

#EndRegion

#Region ProcessingFormData

&AtClient
Procedure CreatingInvoices(CurAdvance = Undefined)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If CurAdvance = Undefined Then
		Result = GenerateInvoicesServer()
	Else
		Result = GenerateInvoicesServer(CurAdvance, True);
	EndIf;
	
	UpdateDisplayOfInformationLabel();
	
	ShowUserNotification(NStr("vi = 'Đã kết thúc lập hóa đơn GTGT cho khoản ứng trước';
								|ru = 'Завершено формирование с/ф на аванс';
								|en = 'Advance payment invoice generated'; fa = 'Advance payment invoice generated';
								|it = 'La fattura per il pagamento anticipato è stata creata';
								|pl = 'Zakończono generowanie faktury dla zaliczki';
								|tr = 'Avans faturası oluşturma tamamlandı'"));
	NotifyChanged(Type("DocumentRef.IssuedTaxInvoicePrepayment"));
	
	If Not Result Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Khi lập hóa đơn GTGT đã xảy ra lỗi. Chi tiết xem trong nhật ký sự kiện.';
				|ru = 'При формировании счетов-фактур возникли ошибки. Подробнее см. в журнале регистрации.';
				|en = 'Errors occurred while generating tax invoices. For more information, see the event log.'; fa = 'Errors occurred while generating tax invoices. For more information, see the event log.';
				|it = 'Si sono verificati errori durante la creazione della fattura. Consultare il registro per i dettagli.';
				|pl = 'Wystąpiły błędy podczas generowania faktur. Zobacz dziennik rejestracji w poszukiwaniu szczegółów.';
				|tr = 'Vergi faturaları oluşturulurken hatalar meydana geldi. Daha fazla ayrıntı için kayıt defterine bakın.'"));
	EndIf;
	
EndProcedure

&AtServer
Function GenerateInvoicesServer(InvoiceData_1 = Undefined, UpdateAbsolutely = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PrepaymentsFromCustomerLayout.Sfsformed,
	|	PrepaymentsFromCustomerLayout.Counterparty,
	|	PrepaymentsFromCustomerLayout.VATTaxation,
	|	PrepaymentsFromCustomerLayout.Sum,
	|	PrepaymentsFromCustomerLayout.VATRate,
	|	PrepaymentsFromCustomerLayout.LineOfBusiness,
	|	PrepaymentsFromCustomerLayout.VATAmount,
	|	PrepaymentsFromCustomerLayout.DocumentBasis,
	|	PrepaymentsFromCustomerLayout.ARAPObject,
	|	PrepaymentsFromCustomerLayout.DateOfDischarge,
	|	PrepaymentsFromCustomerLayout.DocumentCurrency,
	|	PrepaymentsFromCustomerLayout.CurrencyAmount,
	|	PrepaymentsFromCustomerLayout.TaxInvoiceAmount,
	|	PrepaymentsFromCustomerLayout.TaxInvoice,
	|	PrepaymentsFromCustomerLayout.EmployeeResponsible,
	|	PrepaymentsFromCustomerLayout.Department,
	|	PrepaymentsFromCustomerLayout.Director,
	|	PrepaymentsFromCustomerLayout.ChiefAccountant
	|INTO TableAdvances
	|FROM
	|	&PrepaymentsFromCustomerLayout AS PrepaymentsFromCustomerLayout
	|
	|INDEX BY
	|	PrepaymentsFromCustomerLayout.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|
	|SELECT
	|	TableAdvances.Sfsformed,
	|	TableAdvances.Counterparty                                       AS Counterparty,
	|	TableAdvances.VATTaxation                               AS VATTaxation,
	|	ISNULL(TableAdvances.Counterparty.TIN, """")                   AS TINOfCounterparty,
	|	TableAdvances.Sum                                            AS Sum,
	|	TableAdvances.VATRate                                        AS VATRate,
	|	TableAdvances.LineOfBusiness                          AS LineOfBusiness,
	|	TableAdvances.VATAmount                                         AS VATAmount,
	|	TableAdvances.DocumentBasis                                AS DocumentBasis,
	|	TableAdvances.DateOfDischarge                                      AS DateOfDischarge,
	|	TableAdvances.DocumentCurrency                                  AS DocumentCurrency,
	|	TableAdvances.CurrencyAmount                                    AS CurrencyAmount,
	|	TableAdvances.TaxInvoiceAmount                                AS TaxInvoiceAmount,
	|	TableAdvances.TaxInvoice                                      AS TaxInvoice,
	|	TableAdvances.EmployeeResponsible                                    AS EmployeeResponsible,
	|	TableAdvances.Department                                    AS Department,
	|	TableAdvances.Director                                     AS Director,
	|	TableAdvances.ChiefAccountant                                 AS ChiefAccountant,
	|	TableAdvances.ARAPObject                                   AS ARAPObject,
	|	CASE 
	|		WHEN TableAdvances.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                                          AS VATRateIsEmpty,
	|	CASE
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.OBEntryARAP)
	|			THEN ISNULL(OBEntryARAP.NumberOfARAPDocument, SourceDocumentsData.Number)
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.ReversingEntry)
	|			THEN UNDEFINED
	|		ELSE ISNULL(OBEntry.NumberOfARAPDocument, SourceDocumentsData.Number)
	|	END AS SettlementDocumentNumber,
	|	CASE
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.OBEntryARAP)
	|			THEN ISNULL(OBEntryARAP.APARDocumentDate, SourceDocumentsData.Date)
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.ReversingEntry)
	|			THEN UNDEFINED
	|		ELSE ISNULL(OBEntry.APARDocumentDate, SourceDocumentsData.Date)
	|	END AS DateOfDocumentInARAPAccounting
	|FROM
	|	TableAdvances AS TableAdvances
	|	
	|	LEFT JOIN
	|		Document.OBEntry.PartnersARAPAccounting AS OBEntry
	|	ON
	|		TableAdvances.DocumentBasis = OBEntry.Ref
	|		AND TableAdvances.Counterparty = OBEntry.Counterparty
	|
	|	LEFT JOIN
	|		Document.OBEntryARAP.PartnersARAPAccounting AS OBEntryARAP
	|	ON
	|		TableAdvances.DocumentBasis = OBEntryARAP.Ref
	|		AND TableAdvances.Counterparty = OBEntryARAP.Counterparty
	|	
	|	LEFT JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		SourceDocumentsData.Organization = &Organization
	|		AND TableAdvances.DocumentBasis = SourceDocumentsData.Document
	|
	|ORDER BY
	|	TableAdvances.DateOfDischarge,
	|	TableAdvances.Counterparty,
	|	TableAdvances.DocumentBasis
	|
	|TOTALS
	|	SUM(Sum),
	|	SUM(TaxInvoiceAmount),
	|	MAX(VATRateIsEmpty),
	|	MAX(TaxInvoice),
	|	MAX(EmployeeResponsible),
	|	MAX(Department),
	|	MAX(Director),
	|	MAX(ChiefAccountant),
	|	MAX(DateOfDischarge),
	|	MAX(SettlementDocumentNumber),
	|	MAX(DateOfDocumentInARAPAccounting)
	|BY
	|	DocumentBasis,
	|	VATTaxation,
	|	Counterparty
	|";
	
	If InvoiceData_1 <> Undefined Then
		String = PrepaymentsFromCustomerLayout.FindByID(InvoiceData_1);
		Filter = New Structure("DocumentBasis", String.DocumentBasis);
	Else
		Filter = New Structure("Selected", True);
	EndIf;
	AdvanceLines = PrepaymentsFromCustomerLayout.FindRows(Filter);
	Query.SetParameter("PrepaymentsFromCustomerLayout", PrepaymentsFromCustomerLayout.Unload(AdvanceLines));
	Query.SetParameter("Organization",       Organization);
	
	TableOfProcessed = New ValueTable;
	TableOfProcessed.Columns.Add("DocumentBasis");
	TableOfProcessed.Columns.Add("VATTaxation");
	TableOfProcessed.Columns.Add("Counterparty");
	TableOfProcessed.Columns.Add("InvoiceParameters");
	
	TableErrorsOccurred = New ValueTable;
	TableErrorsOccurred.Columns.Add("DocumentBasis");
	TableErrorsOccurred.Columns.Add("VATTaxation");
	TableErrorsOccurred.Columns.Add("Counterparty");
	TableErrorsOccurred.Columns.Add("MessageText");
	
	SampleDocumentBase = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleDocumentBase.Next() Do
		SamplingVATTaxation = SampleDocumentBase.Select(QueryResultIteration.ByGroups);
		While SamplingVATTaxation.Next() Do
			CounterpartySelection = SamplingVATTaxation.Select(QueryResultIteration.ByGroups);
			While CounterpartySelection.Next() Do
				
				InvoiceAmountUpdateRequired = CounterpartySelection.Sum <> CounterpartySelection.TaxInvoiceAmount Or UpdateAbsolutely;
				If CounterpartySelection.VATRateIsEmpty And InvoiceAmountUpdateRequired Then
					Filter = New Structure();
					Filter.Insert("DocumentBasis",  CounterpartySelection.DocumentBasis);
					Filter.Insert("VATTaxation", CounterpartySelection.VATTaxation);
					Filter.Insert("Counterparty",         CounterpartySelection.Counterparty);
					Filter.Insert("VATRate",          Catalogs.VATRates.EmptyRef());
					RowsVATRateIsEmpty = PrepaymentsFromCustomerLayout.FindRows(Filter);
					For Each String In RowsVATRateIsEmpty Do
						MessageText = StrTemplate(NStr("vi = 'Để điền hóa đơn GTGT theo ""%1"" cần chỉ ra Thuế suất GTGT';
														|ru = 'Для заполнения счета-фактуры по ""%1"" требуется указать Ставку НДС';
														|en = 'Specify VAT Rate to fill in tax invoice using ""%1""'; fa = 'Specify VAT Rate to fill in tax invoice using ""%1""';
														|it = 'Per compilare la fattura secondo ""%1"" bisogna indicare l''aliquota IVA';
														|pl = 'Aby wypełnić faktury wg ""%1"" należy podać Stawkę VAT';
														|tr = '""%1"" faturasını tamamlamak için KDV oranı gereklidir'"), String.DocumentBasis);
						DataPath = StrTemplate("PrepaymentsFromCustomerLayout[%1].VATRate", String.GetID());
						Common.MessageToUser(MessageText, , DataPath);
					EndDo;
					Continue;
				EndIf;
				
				TaxInvoiceDate = EndOfDay(SampleDocumentBase.DateOfDischarge);
				If Not ValueIsFilled(CounterpartySelection.TaxInvoice) Then
					InvoiceObject = Documents.IssuedTaxInvoicePrepayment.CreateDocument();
					InvoiceObject.Organization = Organization;
				Else
					InvoiceObject = CounterpartySelection.TaxInvoice.GetObject();
				EndIf; 
				
				FillPropertyValues(InvoiceObject, CounterpartySelection);
				
				InvoiceObject.Date = TaxInvoiceDate;
				InvoiceObject.IssueDate = TaxInvoiceDate;
				InvoiceObject.RuleOfPrepaymentFilter = RuleOfPrepaymentFilter;
				
				If TypeOf(CounterpartySelection.DocumentBasis) = Type("DocumentRef.ARAPSettlement")
					And CounterpartySelection.DocumentBasis.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
					And ValueIsFilled(CounterpartySelection.DocumentBasis.AccountsPayable[0].ARAPObject) Then
						InvoiceObject.CommissionAgreement = CounterpartySelection.DocumentBasis.AccountsPayable[0].ARAPObject.Contract;
				EndIf;
				
				InvoiceObject.Fill(Undefined); // Called so that the refilling of the object has worked
				
				Selection = CounterpartySelection.Select();
				InvoiceParameters = New Map;
				
				If InvoiceAmountUpdateRequired Then
					InvoiceObject.Prepayments.Clear();
					TaxInvoiceAmount = 0;
					While Selection.Next() Do
						NewAdvanceLine = InvoiceObject.Prepayments.Add();
						NewAdvanceLine.InventoryType              = Enums.InventoryTypes.OwnGoods;
						NewAdvanceLine.Sum                   = Selection.Sum;
						NewAdvanceLine.VATRate               = Selection.VATRate;
						NewAdvanceLine.VATAmount                = Selection.VATAmount;
						NewAdvanceLine.LineOfBusiness = Selection.LineOfBusiness;
						NewAdvanceLine.ARAPObject          = Selection.ARAPObject;
						TaxInvoiceAmount = TaxInvoiceAmount + Selection.Sum;
					EndDo;
					InvoiceParameters.Insert(NewAdvanceLine.VATRate, TaxInvoiceAmount);
				EndIf;
				
				Selection.Reset();
				If Selection.Next() Then
					InvoiceObject.TINOfCounterparty = Selection.TINOfCounterparty;
				EndIf;
				
				If UseSalesOrders Then
					// We will fill in the goods invoices for orders
					Goods = Documents.IssuedTaxInvoicePrepayment.CustomerOrderProducts(
								InvoiceObject.DocumentBasis,
								InvoiceObject.VATTaxation);
					If Goods.Count() <> 0 Then
						TableAdvances = InvoiceObject.Prepayments.Unload();
						Documents.IssuedTaxInvoicePrepayment.DistributeAdvancesOnGoods(TableAdvances, Goods, InvoiceObject.DocumentBasis);
						InvoiceObject.Prepayments.Load(TableAdvances);
					EndIf;
				EndIf;
			
				// We will add the remaining details of the document
				InvoiceObject.Fill(Undefined);
				
				// We will fill in the individual details, as indicated in the workplace.
				FillPropertyValues(InvoiceObject, CounterpartySelection, "EmployeeResponsible,Department,Director,ChiefAccountant");
	
				// We will conduct an invoice
				Try
					InvoiceObject.Write(DocumentWriteMode.Posting);
					InvoiceParameters.Insert("TaxInvoice", InvoiceObject.Ref);
					
					NewRow = TableOfProcessed.Add();
					NewRow.DocumentBasis = CounterpartySelection.DocumentBasis;
					NewRow.VATTaxation = CounterpartySelection.VATTaxation;
					NewRow.Counterparty = CounterpartySelection.Counterparty;
					NewRow.InvoiceParameters = InvoiceParameters;
					
					If TypeOf(InvoiceObject.DocumentBasis) = Type("DocumentRef.ReversingEntry") Then
						ShowInformationLabel = True;
					EndIf;
					
					Except
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Không thể hoàn thành do  %1';
								|ru = 'Не удалось выполнить по причине %1';
								|en = 'Cannot execute. Reason: %1'; fa = 'Cannot execute. Reason: %1';
								|it = 'Non è stato possibile eseguire il comando a causa di %1';
								|pl = 'Nie udało się wykonać z powodu %1';
								|tr = '%1 nedeniyle başarısız oldu'"),
							DetailErrorDescription(ErrorInfo()));
							
					WriteLogEvent(
						NStr("vi = 'Lập hóa đơn GTGT cho khoản ứng trước.';
							|ru = 'Формирование счетов-фактур на аванс.';
							|en = 'Generate tax invoices for advance.'; fa = 'Generate tax invoices for advance.';
							|it = 'Formazione di fatture per anticipo';
							|pl = 'Generowanie faktur dla zaliczki';
							|tr = 'Avans ödemeleri için fatura oluşturma.'", Common.DefaultLanguageCode()), 
						EventLogLevel.Error, , , MessageText); 
						
					NewRow = TableErrorsOccurred.Add();
					NewRow.DocumentBasis = CounterpartySelection.DocumentBasis;
					NewRow.VATTaxation = CounterpartySelection.VATTaxation;
					NewRow.Counterparty = CounterpartySelection.Counterparty;
					NewRow.MessageText = MessageText;
					
				EndTry;
			EndDo;
		EndDo;
	EndDo;
	
	TableOfProcessed.Indexes.Add("DocumentBasis, Counterparty");
	TableErrorsOccurred.Indexes.Add("DocumentBasis, Counterparty");
	
	// Update information about invoices
	If InvoiceData_1 <> Undefined Then
		String = PrepaymentsFromCustomerLayout.FindByID(InvoiceData_1);
		UpdateInvoiceDataInLine(String, TableOfProcessed, TableErrorsOccurred);
	Else
		For Each String In PrepaymentsFromCustomerLayout Do
			UpdateInvoiceDataInLine(String, TableOfProcessed, TableErrorsOccurred);
		EndDo;
	EndIf;
	
	Result = (TableErrorsOccurred.Count() = 0);
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateInvoiceDataInLine(String, TableOfProcessed,  TableErrorsOccurred)
	
	Filter = New Structure;
	Filter.Insert("DocumentBasis",  String.DocumentBasis);
	Filter.Insert("Counterparty",         String.Counterparty);
	Filter.Insert("VATTaxation", String.VATTaxation);
	
	SearchResultForProcessed = TableOfProcessed.FindRows(Filter);
	ErrorSearchResult = TableErrorsOccurred.FindRows(Filter);
	
	If SearchResultForProcessed.Count() <> 0 Then
		String.Sfsformed = True;
		InvoiceParameters = SearchResultForProcessed[0].InvoiceParameters;
		If InvoiceParameters[String.VATRate] <> Undefined Then
			String.TaxInvoiceAmount = InvoiceParameters[String.VATRate];
		EndIf;
		String.TaxInvoice = InvoiceParameters["TaxInvoice"];
		If TypeOf(String.DocumentBasis) = Type("DocumentRef.ReversingEntry") Then
			String.PaymentAndSettlementDocumentDataIsMissing = True;
		EndIf;
	ElsIf ErrorSearchResult.Count() <> 0 Then
		String.Sfsformed = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteUnusedInvoicesServer()
	
	For Each InvoiceData_1 In UnusedTaxInvoices Do
		DocumentObject = InvoiceData_1.Value.GetObject();
		DocumentObject.SetDeletionMark(True);
	EndDo; 
	
	FillInUnusedInvoices();
	
EndProcedure

#EndRegion

#Region Appearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayoutVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayoutVATAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.Sfsformed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã chỉ ra trong hóa đơn GTGT';
													|ru = 'Указана в СФ';
													|en = 'Specified in tax invoice'; fa = 'Specified in tax invoice';
													|it = 'Indicata nella fattura';
													|pl = 'Podana w fakturze';
													|tr = 'Faturada belirtilmiştir'"));
	Item.Appearance.SetParameterValue("ReadOnly", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayoutVATRate.Name);
	
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.Sfsformed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.VATRates.EmptyRef();
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayoutCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã chỉ ra trong hóa đơn GTGT';
													|ru = 'Указано в СФ';
													|en = 'Indicated in tax invoice'; fa = 'Indicated in tax invoice';
													|it = 'Indicato nella fattura';
													|pl = 'Podano w fakturze';
													|tr = 'Faturada belirtilmiştir'"));
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayoutVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PrepaymentsFromCustomerLayout.Sfsformed");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PrepaymentsFromCustomerLayout.VATTaxation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SubjectToVATAtCustomer;

	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = 'Thuế GTGT trích bởi đại lý thuế';
															|ru = 'НДС исчисляется налоговым агентом';
															|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
															|it = 'L''IVA viene calcolata dall''agente tributario';
															|pl = 'VAT jest obliczany przez agenta podatkowego';
															|tr = 'KDV vergi memuru tarafından hesaplanır'"));
	Item.Appearance.SetParameterValue("ReadOnly", False);

	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayout.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.RuleOfPrepaymentFilter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments;//;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayout.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.SumError");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", New Color(255, 200, 200));
	
	//

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrepaymentsFromCustomerLayout.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrepaymentsFromCustomerLayout.PaymentAndSettlementDocumentDataIsMissing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", New Color(255, 200, 200));

EndProcedure

&AtServer
Procedure SetDefaultValues()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	BeginOfPeriod = BegOfQuarter(CurrentSessionDate());
	EndOfPeriod = EndOfQuarter(CurrentSessionDate());
	
	If Not ValueIsFilled(VATRate) Then
		VATRate = VATAccountingERP.DefaultVATRate(Organization, BeginOfPeriod);
		IssuedTaxInvoicePrepaymentLocalization.SetAdvanceVATRate(VATRate);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(ThisForm, SelectionResult, "BeginOfPeriod,EndOfPeriod");
	
	WhenSelectionChanges();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function ParametersOfVATRateSelectionForm()
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("VATTaxationType", Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	IssuedTaxInvoicePrepaymentLocalization.SupplementParametersOfFormForSelectingNDSRateAtWorkplace(ChoiceFormParameters);
	
	Return ChoiceFormParameters;
	
EndFunction  

&AtClient
Procedure SetVATRateCompletion(Result, AdditionalParameters) Export
	
	VATRate = Result;
	If ValueIsFilled(VATRate) Then
		SetVATRateOnServer(VATRate);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVATRateOnServer(VATRate)
	
	StructureOfRecalculationOfAmount = RecalculationOfAmountOfNDSVToTS();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		PrepaymentsFromCustomerLayout, Items.PrepaymentsFromCustomerLayout.SelectedRows);
	RowsToProcess = New Array();
	
	For Each String In SelectedRows Do
		String.VATRate = VATRate;
		RowsToProcess.Add(String);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		PrepaymentsFromCustomerLayout,
		CachedValues);
	
EndProcedure

&AtClient
Procedure SetProps(ProcessingParameters)
	
	CallbackDescription = New CallbackDescription("SetPropsCompletion", ThisObject, ProcessingParameters);
	OpenForm(ProcessingParameters.AttributeType + ".ChoiceForm", ProcessingParameters, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SetPropsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowIndex In Items.PrepaymentsFromCustomerLayout.SelectedRows Do
		RowData = Items.PrepaymentsFromCustomerLayout.RowData(RowIndex);
		If RowData[AdditionalParameters.PropsName] <> Result Then
			RowData[AdditionalParameters.PropsName] = Result;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function RecalculationOfAmountOfNDSVToTS()

	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("PriceIncludesVAT", True);
	
	Return PriceFillingStructure;

EndFunction

&AtServer
Procedure EstablishRuleForSelectionOfAdvancesReceived()
	
	// Get the value from the accounting policy
	VATAccountingSettings= AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
			Organization,
			EndOfPeriod,
			True);
	If VATAccountingSettings = Undefined Then
		RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay;
	Else
		RuleOfPrepaymentFilter = VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices;
	EndIf;
	
	// Let's form a selection list taking into account the selected period
	ListSelection_ = Items.RulesForSelectingReceivedAdvances.ChoiceList;
	ListSelection_.Clear();
	
	ListSelection_.Add(Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay);
	
	If BegOfDay(EndOfPeriod) - BegOfDay(BeginOfPeriod) >= 5 * 86400 Then
		ListSelection_.Add(Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays);
	EndIf;
	
	If EndOfDay(EndOfPeriod) = EndOfMonth(EndOfPeriod) Then
		ListSelection_.Add(Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd);
	EndIf;
	
	If EndOfDay(EndOfPeriod) = EndOfQuarter(EndOfPeriod) Then
		ListSelection_.Add(Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd);
	EndIf;
	
	If ListSelection_.FindByValue(RuleOfPrepaymentFilter) = Undefined Then
		RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay;
	EndIf;
	
EndProcedure


&AtServer
Procedure SetValuesForFormParameters(Var_Parameters)
	
	QuickFilterStructure = Undefined;
	Var_Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("BeginOfPeriod", BeginOfPeriod);
		QuickFilterStructure.Property("EndOfPeriod", EndOfPeriod);
		QuickFilterStructure.Property("RuleOfPrepaymentFilter", RuleOfPrepaymentFilter);
		QuickFilterStructure.Property("FilterState", FilterState);
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
		
EndProcedure

&AtServer
Procedure SetHeaderUnusedInvoices()

	If UnusedTaxInvoices.Count() = 0 Then
		TitleText = NStr("vi = 'Hóa đơn GTGT không sử dụng';
						|ru = 'Неиспользуемые счета-фактуры';
						|en = 'Unused tax invoices'; fa = 'صورت‌حساب‌های مالیاتی استفاده‌نشده';
						|it = 'Fatture non utilizzate';
						|pl = 'Niewykorzystane faktury';
						|tr = 'Kullanılmayan vergi faturaları'");
		Visible = False;
	Else
		TitleText = StrTemplate(
			NStr("vi = 'Hóa đơn GTGT không sử dụng (%1)';
				|ru = 'Неиспользуемые счета-фактуры (%1)';
				|en = 'Unused tax invoices (%1)'; fa = 'Unused tax invoices (%1)';
				|it = 'Fatture non utilizzate (%1)';
				|pl = 'Niewykorzystane faktury (%1)';
				|tr = 'Kullanılmayan vergi faturaları (%1)'"), 
			UnusedTaxInvoices.Count());
		Visible = True;
	EndIf;
	
	Items.UnusedInvoicesGroup.Title = TitleText;
	Items.UnusedInvoicesGroup.TitleTextColor = StyleColors.OverdueDataColor;
	Items.UnusedInvoicesGroup.Visible = Visible;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommands()
	
	VisibilityOfCommands = False;
	
	If IsInRole("AddEditIssuedTaxInvoicesForPrepayment") Or
		 IsInRole("FullAccess") Then
		 	VisibilityOfCommands = True;
	EndIf;
	
	Items.RegisterInvoicesAll.Visible = VisibilityOfCommands;
	Items.PrepaymentsFromCustomerLayoutSetVATRate.Visible = VisibilityOfCommands;
	Items.GroupSetBankingDetails.Visible = VisibilityOfCommands;
	Items.PrepaymentsFromCustomerLayoutSelect.Visible = VisibilityOfCommands;
	Items.PrepaymentsFromCustomerLayoutExclude.Visible = VisibilityOfCommands;
	
EndProcedure

&AtServer
Procedure SetFieldVisibility()
	
	If GetFunctionalOption("BaseVersion") Then
		Items.PrepaymentsFromCustomerLayoutDepartment.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SetStateSelection(TableAdvancesReceived_, FilterState)

	If FilterState = "InvoiceRegistrationRequired" Then
		TableAdvancesReceived_.RowFilter = New FixedStructure("TaxInvoice",PredefinedValue("Document.IssuedTaxInvoicePrepayment.EmptyRef"));
	ElsIf FilterState = "AmountsOfAdvanceAndFSFDiffer" Then
		TableAdvancesReceived_.RowFilter = New FixedStructure("SumError", True);
	ElsIf FilterState = "BaseIsStorno" Then
		TableAdvancesReceived_.RowFilter = New FixedStructure("BaseIsStorno", True);
	ElsIf FilterState = "PaymentAndSettlementDocumentDataIsMissing" Then
		TableAdvancesReceived_.RowFilter = New FixedStructure("PaymentAndSettlementDocumentDataIsMissing", True);
	Else
		TableAdvancesReceived_.RowFilter = Undefined;
	EndIf;

EndFunction

&AtClient
Procedure UpdateDisplayOfInformationLabel()
	
	Items.InformationGroup.Visible = ShowInformationLabel;
	
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

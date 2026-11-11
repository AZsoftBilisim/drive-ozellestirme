#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	// Let's clear the tabular parts of the document.
	SummaryRecords.Clear();
	DetailedRecords.Clear();
	
	Organization			= SettingsValueCached.GetDefaultOrganization(Organization);
	Status				= Enums.StatusesOfARAPReconciliation2_5_11.CreatedOn_;
	Manager			= Users.CurrentUser();
	Author				= Users.CurrentUser();
	CounterpartyNumber	= "";
	
	InitializeDocument();
	
	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	ThereAreDiscrepancies = False;
	If TypeOf(FillingData) = Type("Structure") Then
		FillInDocumentAccordingToAssistant(FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckIfPeriodIsCorrect(Cancel);
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("DetailedRecords.PaymentType_");
	If ValueIsFilled(PaymentType_) Then
		NotCheckedAttributeArray.Add("SummaryRecords.PaymentType_");
	EndIf;
	
	If ValueIsFilled(Partner) Or ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts Then
		NotCheckedAttributeArray.Add("SummaryRecords.Partner");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
		
	Filter = New Structure("PaymentType_", Enums.PartnersARAPAccountingTypes.EmptyRef());
	RowsWithoutOwner = DetailedRecords.FindRows(Filter);
	If RowsWithoutOwner.Count() > 0 Then
		MessageText = NStr("vi = 'Đã tìm thấy bản ghi chi tiết bằng trường trống ""Kiểu hạch toán"".
		|Cần chuyển sang bảng ""Bản ghi chi tiết"" và bỏ lọc theo đối tượng hạch toán';
		|ru = 'Обнаружены детальные записи пустым полем ""Тип расчетов"".
		|Необходимо переключиться в таблицу ""Детальные записи"" и отключить отбор по объекту расчетов';
		|en = 'Detailed records with an empty ""Payment type"" field are found.
		|Go to the ""Detailed records"" table and disable the filter by AR/AP object'; fa = 'Detailed records with an empty ""Payment type"" field are found.
		|Go to the ""Detailed records"" table and disable the filter by AR/AP object';
		|it = 'Обнаружены детальные записи пустым полем ""Тип расчетов"".
		|Необходимо переключиться в таблицу ""Детальные записи"" и отключить отбор по объекту расчетов';
		|pl = 'Detailed records with an empty ""Payment type"" field are found.
		|Go to the ""Detailed records"" table and disable the filter by AR/AP object';
		|tr = '""Hesaplama türü"" alanı boş olan ayrıntılı kayıtlar tespit edildi.
		|""Ayrıntılı kayıtlar"" tablosuna geçmek ve hesaplama nesnesine göre seçimi devre dışı bırakmak gerekmektedir'");
		Common.MessageToUser(MessageText, ThisObject, "DetailedRecords",,Cancel);
		For Each LineOfATabularSection In RowsWithoutOwner Do
			MessageText = NStr("vi = 'Trong dòng %1, chưa điền trường ""Kiểu hạch toán"".';
								|ru = 'В строке %1 не заполнено поле ""Тип расчетов"".';
								|en = '""Payment type"" is required in line %1'; fa = '""Payment type"" is required in line %1';
								|it = 'В строке %1 не заполнено поле ""Тип расчетов"".';
								|pl = '""Payment type"" is required in line %1';
								|tr = '%1 satırında ""Hesap türleri"" alanı doldurulmadı.'");
			MessageText = StrReplace(MessageText, "%1", LineOfATabularSection.LineNumber);
			Common.MessageToUser(
						MessageText,
						ThisObject,
						CommonClientServer.PathToTabularSection("DetailedRecords", LineOfATabularSection.LineNumber, "PaymentType_"),
						,
						Cancel);
		EndDo;
	EndIf;
	If ThereAreDiscrepancies And Status = Enums.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes Then
		For Each LineOfATabularSection In SummaryRecords Do
			If LineOfATabularSection.ContractNumber <> LineOfATabularSection.ContractNumberCounterparty
				Or LineOfATabularSection.ContractDate_ <> LineOfATabularSection.ContractDateCounterparty Then
				MessageText = NStr("vi = 'Đã so sánh không phải tất cả các bản ghi tổng kết.';
									|ru = 'Не все итоговые записи сопоставлены.';
									|en = 'Some summary records are not mapped.'; fa = 'Some summary records are not mapped.';
									|it = 'Не все итоговые записи сопоставлены.';
									|pl = 'Some summary records are not mapped.';
									|tr = 'Tüm özet kayıtlar eşleştirilmedi.'");
				Common.MessageToUser(MessageText,, "SummaryRecords", "Object", Cancel);
				Break;
			EndIf;
		EndDo;

		For Each LineOfATabularSection In DetailedRecords Do
			If LineOfATabularSection.DocumentNumber <> LineOfATabularSection.IncomingNumberCounterparty
				Or LineOfATabularSection.DocumentDate <> LineOfATabularSection.DocumentDateCounterparty Then
				MessageText = NStr("vi = 'Đã so sánh không phải tất cả các bản ghi chi tiết.';
									|ru = 'Не все детальные записи сопоставлены.';
									|en = 'Some detailed records are not mapped.'; fa = 'Some detailed records are not mapped.';
									|it = 'Не все детальные записи сопоставлены.';
									|pl = 'Some detailed records are not mapped.';
									|tr = 'Tüm ayrıntılı kayıtlar eşleştirilmedi.'");
				Common.MessageToUser(MessageText,, "DetailedRecords", "Object", Cancel);
				Break;
			EndIf;
		EndDo;
	EndIf;

	If ThereAreDiscrepancies And Status <> Enums.StatusesOfARAPReconciliation2_5_11.IsRejected Then
		CheckThatCounterpartySDataIsFilledInCorrectly(Cancel);
		CheckCorrectnessOfEntriesLineByLine(Cancel);
		CheckCorrectnessOfEntriesByDimensions(Cancel);
	EndIf;

	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_5_11.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf; 

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SetPropertiesForChangingBankingDetails(ThisObject, AdditionalProperties);
	
	ARAPAccountingClientServer.UpdateObjectReconciliationState(ThisObject);
	
	//Used in the EDI library to record the State of the exchange
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined) Export
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfARAPReconciliation.CreatedOn_;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = CurrentSessionDate();
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(ContactPerson) Then
		ContactPerson = PartnersAndCounterparties.GetDefaultCounterpartyPartnerContactPerson(Counterparty);
	EndIf;
	
EndProcedure

Procedure FillInDocumentAccordingToAssistant(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	FillingData.Insert("Date", Date);
	
	DocumentData = Documents.ARAPReconciliation2_5_11.DetailsOfLastDocument(Counterparty);
	FillPropertyValues(ThisObject, DocumentData, "FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive");
	
	If FillingData.Property("Filter_Settings") Then
		SetSelectionsForEquality(FillingData);
		Filter_Settings = New ValueStorage(FillingData.Filter_Settings);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Documents.ARAPReconciliation2_5_11.FillInCalculationData(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCorrectnessOfEntriesLineByLine(Cancel)

	For Each FinalRecord In SummaryRecords Do
		If FinalRecord.PaymentType_.IsEmpty() Then	// Organization data is missing
			Continue;
		EndIf;

		If FinalRecord.ClosingBalanceDrCounterparty <> 0 And FinalRecord.ClosingBalanceCrCounterparty <> 0 Then	// expanded balance, separate calculation of Dr/Cr is required
			DataCorrect = FinalRecord.OpeningBalanceDrCounterparty
				+ FinalRecord.TurnoverDrCounterparty
				= FinalRecord.ClosingBalanceDrCounterparty
				And FinalRecord.OpeningBalanceCrCounterparty
				+ FinalRecord.TurnoverCrCounterparty
				= FinalRecord.ClosingBalanceCrCounterparty;
		Else
			DataCorrect = FinalRecord.OpeningBalanceDrCounterparty - FinalRecord.OpeningBalanceCrCounterparty
				+ FinalRecord.TurnoverDrCounterparty - FinalRecord.TurnoverCrCounterparty
				= FinalRecord.ClosingBalanceDrCounterparty - FinalRecord.ClosingBalanceCrCounterparty;
		EndIf;

		If Not DataCorrect Then
			If FinalRecord.ClosingBalanceDrCounterparty <> 0 Then
				TurnoverAttributes = ".ClosingBalanceDrCounterparty";
			ElsIf FinalRecord.ClosingBalanceCrCounterparty <> 0 Then
				TurnoverAttributes = ".ClosingBalanceCrCounterparty";
			Else
				TurnoverAttributes = "";
			EndIf;
			MessageText = NStr("vi = 'Số tiền dư đầu và phát sinh không bằng với dư cuối.';
								|ru = 'Сумма начального остатка и оборотов не равна конечному остатку.';
								|en = 'The amount of opening balance and turnovers is not equal to the closing balance.'; fa = 'The amount of opening balance and turnovers is not equal to the closing balance.';
								|it = 'Сумма начального остатка и оборотов не равна конечному остатку.';
								|pl = 'The amount of opening balance and turnovers is not equal to the closing balance.';
								|tr = 'Açılış ​​bakiyesi ile ciroların toplamı kapanış bakiyesine eşit değildir.'");
			Common.MessageToUser(MessageText,,
				StringFunctionsClientServer.SubstituteParametersToString("SummaryRecords[%1]%2",
					Format(SummaryRecords.IndexOf(FinalRecord), "NZ=0; NG="),
					TurnoverAttributes),
				"Object",
				Cancel);
		EndIf;
	EndDo;

EndProcedure

Procedure CheckCorrectnessOfEntriesByDimensions(Cancel)

	ReconciliationUnderContracts = ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;

	GroupingColumns = "PaymentType_, Partner, Contract, ARAPObject";
	TotalingColumns = "DebitAmount, AmountDebitCounterparty, LoanAmount_, AmountCreditCounterparty";
	DetailedRecordData = DetailedRecords.Unload(, GroupingColumns + ", " + TotalingColumns);
	DetailedRecordData.GroupBy(GroupingColumns, TotalingColumns);

	CopyOfFinalRecord = New Structure();
	CopyOfFinalRecord.Insert("PaymentType_");
	CopyOfFinalRecord.Insert("Partner");
	CopyOfFinalRecord.Insert("Contract");
	CopyOfFinalRecord.Insert("ARAPObject");
	CopyOfFinalRecord.Insert("OpeningBalanceDrCounterparty");
	CopyOfFinalRecord.Insert("OpeningBalanceCrCounterparty");
	CopyOfFinalRecord.Insert("AmountDebitCounterparty");
	CopyOfFinalRecord.Insert("AmountCreditCounterparty");
	CopyOfFinalRecord.Insert("TurnoverDrCounterparty");
	CopyOfFinalRecord.Insert("TurnoverCrCounterparty");
	CopyOfFinalRecord.Insert("ClosingBalanceDrCounterparty");
	CopyOfFinalRecord.Insert("ClosingBalanceCrCounterparty");

	For Each FinalRecord In SummaryRecords Do
		If FinalRecord.PaymentType_.IsEmpty() Then	// Organization data is missing
			Continue;
		EndIf;
		If FinalRecord.OpeningBalanceDrCounterparty = 0
			And FinalRecord.OpeningBalanceCrCounterparty = 0
			And FinalRecord.TurnoverDrCounterparty = 0
			And FinalRecord.TurnoverCrCounterparty = 0
			And FinalRecord.ClosingBalanceDrCounterparty = 0
			And FinalRecord.ClosingBalanceCrCounterparty = 0 Then	// No counterparty data available
			Continue;
		EndIf;
		
		FillPropertyValues(CopyOfFinalRecord, FinalRecord);
		ARAPAccountingClientServer.CalculateFinalBalanceOfDrCr(CopyOfFinalRecord, DetailedRecordData, ReconciliationUnderContracts, True);
		If CopyOfFinalRecord.TurnoverDrCounterparty <> FinalRecord.TurnoverDrCounterparty Then
			MessageText = NStr("vi = 'Số tiền phát sinh theo bên Nợ trong các bản ghi chi tiết không bằng với phát sinh theo bên Nợ trong bản ghi tổng kết.';
								|ru = 'Сумма оборота по дебету в детальных записях не равна обороту по дебету в итоговой записи.';
								|en = 'The debit turnover amount in detailed records is not equal to the debit turnover in the summary record.'; fa = 'The debit turnover amount in detailed records is not equal to the debit turnover in the summary record.';
								|it = 'Сумма оборота по дебету в детальных записях не равна обороту по дебету в итоговой записи.';
								|pl = 'The debit turnover amount in detailed records is not equal to the debit turnover in the summary record.';
								|tr = 'Ayrıntılı kayıtlardaki borç cirosu tutarı, özet kayıtlardaki borç cirosuna eşit değildir.'");
			Common.MessageToUser(MessageText,,
				StringFunctionsClientServer.SubstituteParametersToString("SummaryRecords[%1].TurnoverDrCounterparty",
					Format(SummaryRecords.IndexOf(FinalRecord), "NZ=0; NG=")),
				"Object",
				Cancel);
		EndIf;
		If CopyOfFinalRecord.TurnoverCrCounterparty <> FinalRecord.TurnoverCrCounterparty Then
			MessageText = NStr("vi = 'Số tiền phát sinh theo bên Có trong các bản ghi chi tiết không bằng phát sinh theo bên Có trong bản ghi tổng kết.';
								|ru = 'Сумма оборота по кредиту в детальных записях не равна обороту по кредиту в итоговой записи.';
								|en = 'The credit turnover amount in detailed records is not equal to the credit turnover in the summary record.'; fa = 'The credit turnover amount in detailed records is not equal to the credit turnover in the summary record.';
								|it = 'Сумма оборота по кредиту в детальных записях не равна обороту по кредиту в итоговой записи.';
								|pl = 'The credit turnover amount in detailed records is not equal to the credit turnover in the summary record.';
								|tr = 'Ayrıntılı kayıtlardaki alacak cirosu tutarı, özet kayıtlardaki alacak cirosuna eşit değildir.'");
			Common.MessageToUser(MessageText,,
				StringFunctionsClientServer.SubstituteParametersToString("SummaryRecords[%1].TurnoverCrCounterparty",
					Format(SummaryRecords.IndexOf(FinalRecord), "NZ=0; NG=")),
				"Object",
				Cancel);
		EndIf;
	EndDo;

EndProcedure

// In details: name, number, date.
Procedure CheckThatCounterpartySDataIsFilledInCorrectly(Cancel)

	ArrayOfVerifiedDetails = StrSplit("DocumentNameCounterparty,IncomingNumberCounterparty,DocumentDateCounterparty", ",");
	MessageTextTemplate = NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 danh sách ""Bản ghi chi tiết"".';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Детальные записи"".';
								|en = 'The ""%1"" column in line %2 of the ""Detailed records"" list is not filled.'; fa = 'The ""%1"" column in line %2 of the ""Detailed records"" list is not filled.';
								|it = 'Не заполнена колонка ""%1"" в строке %2 списка ""Детальные записи"".';
								|pl = 'The ""%1"" column in line %2 of the ""Detailed records"" list is not filled.';
								|tr = '""Ayrıntılı kayıtlar"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı.'");

	For Each LineOfATabularSection In DetailedRecords Do
		If LineOfATabularSection.PaymentType_.IsEmpty() Then
			For Each AttributeToCheck In ArrayOfVerifiedDetails Do
				If Not ValueIsFilled(LineOfATabularSection[AttributeToCheck]) Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						MessageTextTemplate,
						AttributeToCheck,
						LineOfATabularSection.LineNumber);
					Common.MessageToUser(MessageText,,
						StringFunctionsClientServer.SubstituteParametersToString("DetailedRecords[%1].%2",
							Format(SummaryRecords.IndexOf(LineOfATabularSection), "NZ=0; NG="),
							),
						"Object",
						Cancel);
				EndIf;
			EndDo;
		EndIf;
	EndDo;

EndProcedure

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders.
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.StatusesOfARAPReconciliation2_5_11[NewStatus];
	
	Return CheckFilling();
	
EndFunction

Procedure CheckIfPeriodIsCorrect(Cancel)
	
	If ValueIsFilled(BeginOfPeriod)
	 And ValueIsFilled(EndOfPeriod)
	 And BeginOfPeriod > EndOfPeriod Then
	 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ngày đầu kỳ không được lớn hơn ngày cuối kỳ %1';
				|ru = 'Дата начала периода не должна быть больше окончания периода %1';
				|en = 'Period start date cannot exceed the period end date %1'; fa = 'Period start date cannot exceed the period end date %1';
				|it = 'Дата начала периода не должна быть больше окончания периода %1';
				|pl = 'Data rozpoczęcia okresu nie może być większa niż koniec okresu %1';
				|tr = 'Dönemin başlangıç tarihi, %1dönemin bitiş tarihinden sonra olmamalıdır'"),
			Format(EndOfPeriod, "DLF=DD"));
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"BeginOfPeriod",
			, // DataPath
			Cancel);
	 
	EndIf;
	
EndProcedure

Procedure SetSelectionsForEquality(FillingData)
	
	FilterFields = New Array();
	FilterFields.Add("PaymentType_");
	FilterFields.Add("Partner");
	FilterFields.Add("Contract");
	If GetFunctionalOption("UseMultipleCompanies") Then
		FilterFields.Add("Organization");
	EndIf;
	FilterFields.Add("Counterparty");
	
	Filter = FillingData.Filter_Settings.Filter;
	For Each FilterField In FilterFields Do
		SplitDocuments = True;
		If FilterField = "PaymentType_" Then
			SplitDocuments = FillingData.SplitByARAPTypes;
			
		ElsIf FilterField = "Partner" Then
			SplitDocuments = FillingData.SplitByPartners;
			
		ElsIf FilterField = "Contract" Then
			SplitDocuments = FillingData.SplitByContracts;
			
		EndIf;
		If SplitDocuments Then
			FinancialReportingServer.SetFilter(Filter, FilterField, FillingData[FilterField], DataCompositionComparisonType.Equal, SplitDocuments);
		EndIf;
	EndDo;
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(Filter, "ContractsWithoutTurnover");
	FilterContractsWithoutTurnover.Use = FillingData.ContractsWithoutTurnover;
	
EndProcedure

Procedure SetPropertiesForChangingBankingDetails(Object, Var_AdditionalProperties)
		
	OnlyVerifiedOnReconciliationStatusHasChanged = False;
	
	If Object.Posted Then
		
		AttributesNotToCheck = New Structure;
		AttributesNotToCheck.Insert("Comment");
		AttributesNotToCheck.Insert("Filter_Settings");
		
		DocumentChanges = TMCommonUse.DocumentChanges(Object, AttributesNotToCheck);
		
		OtherDetailsChanged = False;
		ChangedStatus_ = False;
		
		If DocumentChanges.Property("TabularSections") Then
			OtherDetailsChanged = True;
		EndIf;                                  
		
		If DocumentChanges.Property("Attributes") Then
			If DocumentChanges.Attributes.Find("Status", "Name") <> Undefined Then
				ChangedStatus_ = True;
			EndIf;
			For Each Attribute In DocumentChanges.Attributes Do
				If Attribute.Name <> "Status" Then
					OtherDetailsChanged = True;
					Break;
				EndIf;
			EndDo;
		EndIf;                                    
		
		OnlyVerifiedOnReconciliationStatusHasChanged = ChangedStatus_ And Not OtherDetailsChanged;
		
	EndIf;
	
	Var_AdditionalProperties.Insert("OnlyVerifiedOnReconciliationStatusHasChanged", OnlyVerifiedOnReconciliationStatusHasChanged);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

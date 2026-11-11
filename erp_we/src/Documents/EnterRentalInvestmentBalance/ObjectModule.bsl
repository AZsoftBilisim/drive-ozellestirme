#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_InputOfBalancesOfInvestmentInRent(ThisObject, AuxiliaryAttributes());
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	CheckFixedAssets(Cancel);
	
	LeasedAssetAccounting.CheckRentalIncomeSchedules(ThisObject, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FillInBankingDetailsBeforeWrite(Cancel, WriteMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;

	Return AuxiliaryAttributes;
	
EndFunction

Procedure CheckFixedAssets(Cancel)
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "ContractType, LeaseContracts");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|INTO TTFATable
	|FROM
	|	&FATable AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssetsLeasedOutSliceLast.FixedAsset AS FixedAsset
	|INTO TTLeasedToFA
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&Date,
	|			FixedAsset IN
	|					(SELECT
	|						TTFATable.FixedAsset AS FixedAsset
	|					FROM
	|						TTFATable AS TTFATable)
	|				AND Recorder <> &Ref) AS AssetsLeasedOutSliceLast
	|WHERE
	|	AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND AssetsLeasedOutSliceLast.Contract <> &Contract
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAssetSliceLast.FixedAsset AS FixedAsset,
	|	LeasedAssetSliceLast.Contract AS Contract,
	|	LeasedAssetSliceLast.State AS State
	|INTO TTLeasedFA
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|			&Date,
	|			FixedAsset IN
	|				(SELECT
	|					TTFATable.FixedAsset AS FixedAsset
	|				FROM
	|					TTFATable AS TTFATable)) AS LeasedAssetSliceLast
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEADD(DATEADD(DATEADD(TermsOfLeaseContractsSliceLast.LeaseStartDate, YEAR, TermsOfLeaseContractsSliceLast.TermYears), MONTH, TermsOfLeaseContractsSliceLast.TermMonths), DAY, TermsOfLeaseContractsSliceLast.TermDays - 1) AS RentalEndDate,
	|	TermsOfLeaseContractsSliceLast.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContractsSliceLast.Contract AS Contract
	|INTO TTTermsOfLeaseContract
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Contract IN
	|				(SELECT
	|					TTLeasedFA.Contract AS Contract
	|				FROM
	|					TTLeasedFA AS TTLeasedFA)) AS TermsOfLeaseContractsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Contract AS Contract,
	|	LeasedAsset.State AS State,
	|	TermsOfLeaseContract.RentalEndDate AS RentalEndDate,
	|	TermsOfLeaseContract.LeaseStartDate AS LeaseStartDate
	|INTO TTLeasedByOSSRentalDates
	|FROM
	|	TTLeasedFA AS LeasedAsset
	|		LEFT JOIN TTTermsOfLeaseContract AS TermsOfLeaseContract
	|		ON LeasedAsset.Contract = TermsOfLeaseContract.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicePaymentSchedule.Date AS Date,
	|	ServicePaymentSchedule.FixedAsset AS FixedAsset
	|INTO TTPaymentsSchedule
	|FROM
	|	&ServicePaymentSchedule AS ServicePaymentSchedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(PaymentSchedule.Date) AS Date,
	|	PaymentSchedule.FixedAsset AS FixedAsset
	|INTO EndDateOfTransferIsTT
	|FROM
	|	TTPaymentsSchedule AS PaymentSchedule
	|
	|GROUP BY
	|	PaymentSchedule.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.LineNumber AS LineNumber,
	|	ISNULL(TransferEndDates.Date, DATETIME(1, 1, 1)) AS SubleaseEndDate,
	|	ISNULL(LeasedAsset.RentalEndDate, DATETIME(1, 1, 1)) AS RentalEndDate,
	|	ISNULL(LeasedAsset.LeaseStartDate, DATETIME(1, 1, 1)) AS LeaseStartDate,
	|	CASE
	|		WHEN &ThisIsTransferForRent
	|				AND LeasedAsset.State IN (VALUE(Enum.FixedAssetsStates.InLease), VALUE(Enum.FixedAssetsStates.LeaseContractsSigned))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FARented,
	|	CASE
	|		WHEN NOT AssetsLeasedOut.FixedAsset IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FAWasLeasedEarlier,
	|	CASE
	|		WHEN &ThisIsSublease
	|				AND LeasedAsset.Contract IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FAIsNotRented,
	|	CASE
	|		WHEN &ThisIsSublease
	|				AND NOT LeasedAsset.Contract IS NULL
	|				AND LeasedAsset.Contract <> &LeaseContracts
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS LeaseContractDoesNotMatch,
	|	CASE
	|		WHEN &ThisIsSublease
	|				AND ISNULL(TransferEndDates.Date, DATETIME(1, 1, 1)) > ISNULL(LeasedAsset.RentalEndDate, DATETIME(1, 1, 1))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TransferEndDateIsLongerThanLeaseTerm,
	|	CASE
	|		WHEN &ThisIsSublease
	|				AND &Date < ISNULL(LeasedAsset.LeaseStartDate, DATETIME(1, 1, 1))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SubleaseTransferDateIsLessThanStartDateOfLease
	|FROM
	|	TTFATable AS FATable
	|		LEFT JOIN TTLeasedByOSSRentalDates AS LeasedAsset
	|		ON FATable.FixedAsset = LeasedAsset.FixedAsset
	|		LEFT JOIN EndDateOfTransferIsTT AS TransferEndDates
	|		ON FATable.FixedAsset = TransferEndDates.FixedAsset
	|		LEFT JOIN TTLeasedToFA AS AssetsLeasedOut
	|		ON FATable.FixedAsset = AssetsLeasedOut.FixedAsset
	|WHERE
	|	(&ThisIsTransferForRent
	|				AND LeasedAsset.State IN (VALUE(Enum.FixedAssetsStates.InLease), VALUE(Enum.FixedAssetsStates.LeaseContractsSigned))
	|			OR NOT AssetsLeasedOut.FixedAsset IS NULL
	|			OR &ThisIsSublease
	|				AND LeasedAsset.Contract IS NULL
	|			OR &ThisIsSublease
	|				AND NOT LeasedAsset.Contract IS NULL
	|				AND LeasedAsset.Contract <> &LeaseContracts
	|			OR &ThisIsSublease
	|				AND ISNULL(TransferEndDates.Date, DATETIME(1, 1, 1)) > ISNULL(LeasedAsset.RentalEndDate, DATETIME(1, 1, 1))
	|			OR &ThisIsSublease
	|				AND &Date < ISNULL(LeasedAsset.LeaseStartDate, DATETIME(1, 1, 1)))";
	
	Query.SetParameter("ThisIsSublease", ContractDetails_.ContractType = Enums.ContractTypes.Sublease);
	Query.SetParameter("ThisIsTransferForRent", ContractDetails_.ContractType = Enums.ContractTypes.TransferToRental);
	Query.SetParameter("LeaseContracts", ContractDetails_.LeaseContracts);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Ref", Ref);	
	Query.SetParameter("FATable", FA.Unload(, "LineNumber, FixedAsset"));
	Query.SetParameter("ServicePaymentSchedule", ServicePaymentSchedule.Unload(, "Date, FixedAsset"));

	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	MessageTemplateFARented =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" mà đã chỉ ra tài sản cố định cho thuê. Có thể chuyển TSCĐ như vậy cho thuê theo hợp đồng có dạng ""Cho thuê lại""';
			|ru = 'В строке %1 списка ""Основные средства"", указано основное средство, находящееся в аренде. Такое ОС можно передать в аренду по договору с типом ""Субаренда""';
			|en = 'Line %1 of the ""Fixed assets"" list contains a leased fixed asset. Such fixed asset can be leased under a contract with the ""Sublease"" type'; fa = 'Line %1 of the ""Fixed assets"" list contains a leased fixed asset. Such fixed asset can be leased under a contract with the ""Sublease"" type';
			|it = 'В строке %1 списка ""Основные средства"", указано основное средство, находящееся в аренде. Такое ОС можно передать в аренду по договору с типом ""Субаренда""';
			|pl = 'Line %1 of the ""Fixed assets"" list contains a leased fixed asset. Such fixed asset can be leased under a contract with the ""Sublease"" type';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, kiralamada bulunan bir sabit kıymet bulunmaktadır. Söz konusu sabit kıymet, ""Alt kiralama"" tipindeki sözleşme kapsamında kiralanabilir.'");
	MessageTemplateFALeasedEarlier =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", đã chỉ ra tài sản cố định mà được chuyển cho thuê trước đó';
			|ru = 'В строке %1 списка ""Основные средства"", указано основное средство, уже переданное в аренду ранее';
			|en = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is already leased'; fa = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is already leased';
			|it = 'В строке %1 списка ""Основные средства"", указано основное средство, уже переданное в аренду ранее';
			|pl = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is already leased';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, daha önce kiraya verilen bir sabit kıymet belirtildi'");
	MessageTemplateOfFAIsNotRented =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"" mà đã chỉ ra tài sản cố định không cho thuê. Có thể chuyển TSCĐ như vậy cho thuê theo hợp đồng có dạng ""Cho thuê lại""';
			|ru = 'В строке %1 списка ""Основные средства"", указано основное средство, не находящееся в аренде. Такое ОС можно передать в аренду по договору с типом ""Передача в аренду""';
			|en = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is not leased. Such fixed asset can be leased under a contract with the ""Rental"" type'; fa = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is not leased. Such fixed asset can be leased under a contract with the ""Rental"" type';
			|it = 'В строке %1 списка ""Основные средства"", указано основное средство, не находящееся в аренде. Такое ОС можно передать в аренду по договору с типом ""Передача в аренду""';
			|pl = 'Line %1 of the ""Fixed assets"" list contains a fixed asset that is not leased. Such fixed asset can be leased under a contract with the ""Rental"" type';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, kiralamada bulunmayan bir sabit kıymet bulunmaktadır. Söz konusu sabit kıymet, ""Kira devri"" tipindeki sözleşme kapsamında kiralanabilir.'");
	MessageTemplateOfLeaseContractDoesNotMatch =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", hợp đồng thuê của tài sản cố định được thuê không tương ứng với hợp đồng thuê được chỉ ra trong các thuộc tính của hợp đồng đối tác';
			|ru = 'В строке %1 списка ""Основные средства"", договор аренды арендованного основного средства не соответствует договору аренды, указанному в свойствах договора контрагента';
			|en = 'In line %1 of the ""Fixed assets"" list, the rental contract for the leased fixed asset does not correspond to the rental contract specified in the properties of the counterparty contract'; fa = 'In line %1 of the ""Fixed assets"" list, the rental contract for the leased fixed asset does not correspond to the rental contract specified in the properties of the counterparty contract';
			|it = 'В строке %1 списка ""Основные средства"", договор аренды арендованного основного средства не соответствует договору аренды, указанному в свойствах договора контрагента';
			|pl = 'In line %1 of the ""Fixed assets"" list, the rental contract for the leased fixed asset does not correspond to the rental contract specified in the properties of the counterparty contract';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, kiralanan sabit kıymetin kira sözleşmesi, cari hesap sözleşmesinin özelliklerinde belirtilen kira sözleşmesine karşılık gelmemektedir'");
	MessageTemplateTransferEndDateIsLongerThanLeaseTerm =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", ngày kết thúc chuyển cho thuê lại tài sản cố định (%2) lớn hơn ngày kết thúc hợp đồng thuê (%3)';
			|ru = 'В строке %1 списка ""Основные средства"" дата окончания передачи в субаренду основного средства (%2) больше даты окончания договора аренды (%3)';
			|en = 'In line %1 of the ""Fixed assets"" list, the end date of sublease of the fixed asset (%2) is later than the end date of the rental contract (%3)'; fa = 'In line %1 of the ""Fixed assets"" list, the end date of sublease of the fixed asset (%2) is later than the end date of the rental contract (%3)';
			|it = 'В строке %1 списка ""Основные средства"" дата окончания передачи в субаренду основного средства (%2) больше даты окончания договора аренды (%3)';
			|pl = 'In line %1 of the ""Fixed assets"" list, the end date of sublease of the fixed asset (%2) is later than the end date of the rental contract (%3)';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, sabit kıymetin alt kiralama bitiş tarihi (%2) kira sözleşmesinin bitiş tarihinden (%3) sonra değildir'");
	MessageTemplateDateOfTransferToSubleaseIsLessThanStartDateOfLease =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định"", ngày kết thúc chuyển cho thuê lại tài sản cố định (%2) nhỏ hơn ngày kết thúc hợp đồng thuê (%3)';
			|ru = 'В строке %1 списка ""Основные средства"" дата передачи в субаренду основного средства (%2) меньше даты начала договора аренды (%3)';
			|en = 'In line %1 of the ""Fixed assets"" list, the start date of sublease of the fixed asset (%2) is less than the start date of the rental contract (%3)'; fa = 'In line %1 of the ""Fixed assets"" list, the start date of sublease of the fixed asset (%2) is less than the start date of the rental contract (%3)';
			|it = 'В строке %1 списка ""Основные средства"" дата передачи в субаренду основного средства (%2) меньше даты начала договора аренды (%3)';
			|pl = 'In line %1 of the ""Fixed assets"" list, the start date of sublease of the fixed asset (%2) is less than the start date of the rental contract (%3)';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, sabit kıymetin alt kiralama tarihi (%2) kira sözleşmesinin başlangıç tarihinden (%3) önce değildir'");

	While Selection.Next() Do
		
		If Selection.FARented Then
			MessageText = StrTemplate(MessageTemplateFARented, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.FAWasLeasedEarlier Then
			MessageText = StrTemplate(MessageTemplateFALeasedEarlier, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.FAIsNotRented Then
			MessageText = StrTemplate(MessageTemplateOfFAIsNotRented, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.LeaseContractDoesNotMatch Then
			MessageText = StrTemplate(MessageTemplateOfLeaseContractDoesNotMatch, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.TransferEndDateIsLongerThanLeaseTerm Then
			MessageText = StrTemplate(
				MessageTemplateTransferEndDateIsLongerThanLeaseTerm,
				Selection.LineNumber,
				Format(Selection.SubleaseEndDate, "DLF=D"),
				Format(Selection.RentalEndDate, "DLF=D"));
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.SubleaseTransferDateIsLessThanStartDateOfLease Then
			MessageText = StrTemplate(
				MessageTemplateDateOfTransferToSubleaseIsLessThanStartDateOfLease,
				Selection.LineNumber,
				Format(Date, "DLF=D"),
				Format(Selection.LeaseStartDate, "DLF=D"));
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
			
	EndDo;
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite(Cancel, WriteMode)
	
	LeasedAssetAccounting.DeleteIrrelevantGraphLines(ThisObject);
	ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Contract);
	LeasedAssetAccounting.FillInAmountOfRentalPayments(ThisObject, ContractDetails_.ARAPCurrency);
	
EndProcedure

#EndRegion

#EndIf

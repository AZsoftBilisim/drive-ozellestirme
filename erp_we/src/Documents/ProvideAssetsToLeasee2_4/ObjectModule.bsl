#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ProvideAssetsToLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_TransferToOSV(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProvideAssetsToLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	If ValueIsFilled(Organization) And ValueIsFilled(Leaseholder) And (Organization = Leaseholder) Then
		Text = NStr("vi = 'Trường ""Doanh nghiệp"" và ""Người cho thuê"" phải khác nhau.';
					|ru = 'Поля ""Организация"" и ""Арендатор"" должны различаться.';
					|en = 'The ""Company"" and ""Lessee"" fields must be different.'; fa = 'The ""Company"" and ""Lessee"" fields must be different.';
					|it = 'I campi ""Organizzazione"" e ""Locatore"" devono differire tra loro.';
					|pl = 'Pola ""Firma"" i ""Najemca"" powinny różnić się.';
					|tr = '""İş yeri"" ve ""Kiracı"" alanları farklı olmalıdır.'");
		Common.MessageToUser(Text, ThisObject, "Leaseholder",, Cancel);
	EndIf;
	
	If AuxiliaryAttributes.TransferForLeaseUnderFAS25 Then
		CheckFixedAssets(Cancel);
		LeasedAssetAccounting.CheckRentalIncomeSchedules(ThisObject, Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	AdditionalProperties.Insert("AuxiliaryAttributes", AuxiliaryAttributes());
	
	FillInBankingDetailsBeforeWrite(Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting
		And Not AdditionalProperties.AuxiliaryAttributes.TransferForLeaseUnderFAS25 Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		NonCurrentAssetsInternal.FillInReflectionInAccounting(ThisObject, FA.Unload().UnloadColumn("FixedAsset"));
	EndIf;
	
	If Not LeaseholderIntercompanyARAP Then
		LeaseholderBusinessUnit = ReceivingBusinessUnit;
	EndIf; 
	
	If Not ValueIsFilled(LocationAddress) Then
		LocationAddress = "";
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	ItemsAndDimensionsSelectionParameters = Documents.ProvideAssetsToLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
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
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	ReceivingBusinessUnit = Department;
	LeaseholderBusinessUnit = Department;
	
EndProcedure
 
Procedure BlockReadableData()

	// It is necessary to block the data that is used when recording movements.
	// For example, data registers of information that are used to fill in missing resources.
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf; 
	
	ProvideAssetsToLeaseeLocalization.AddBlockingOfReadableDataWhenConducting(ThisObject, Block);
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể chuyển giao cho người cho thuê nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Передача арендатору группы ОС невозможна.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot transfer fixed assets group to lessee.
			|Select fixed assets. To open the group, press Ctrl and the down arrow.'; fa = 'Cannot transfer fixed assets group to lessee.
			|Select fixed assets. To open the group, press Ctrl and the down arrow.';
			|it = 'Non è possibile trasferire al locatore il gruppo di immobilizzazioni. 
			|Selezionare immobilizzazione. Per l''apertura del gruppo utilizzare i tasti Ctrl e freccia su.';
			|pl = 'Przekazanie do dzierżawcy grupy środków trwałych jest niemożliwe.
			|Wybierz środek trwały. Aby otworzyć grupę naciśnij klawisze Ctrl i strzałkę do dołu.';
			|tr = 'Sabit kıymet gruplarını kiracıya aktarmak mümkün değildir.
			|Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	FALocation = NonCurrentAssets.FALocation(Basis);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.FixedAssetsLocation;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
		
	ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Contract);
	TransferForLeaseUnderFAS25 = False;
	If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		If ContractDetails_.ContractType = Enums.ContractTypes.TransferToRental
			Or ContractDetails_.ContractType = Enums.ContractTypes.Sublease Then
			
			TransferForLeaseUnderFAS25 = True;
			
		EndIf;
	EndIf;
	AuxiliaryAttributes.Insert("TransferForLeaseUnderFAS25", TransferForLeaseUnderFAS25);
	AuxiliaryAttributes.Insert("ContractInLocalAccountingCurrency",
		ContractDetails_.ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Return AuxiliaryAttributes;
	
EndFunction

Procedure FillInBankingDetailsBeforeWrite(Cancel, WriteMode)
	
	If AdditionalProperties.AuxiliaryAttributes.TransferForLeaseUnderFAS25 Then
		
		LeasedAssetAccounting.DeleteIrrelevantGraphLines(ThisObject);
		ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Contract);
		LeasedAssetAccounting.FillInAmountOfRentalPayments(ThisObject, ContractDetails_.ARAPCurrency);
		RecordInLocalAccounting = True;
		RecordInManAccounting = True;
		DepreciationAccrualLocalAccounting = Enums.DepreciationAccrualChangeOptions.Stopped;
		DepreciationAccrualMan = Enums.DepreciationAccrualChangeOptions.Stopped;
		
		InterestScheduleUpdated = False;
		If Not AdditionalProperties.Property("InterestScheduleUpdated", InterestScheduleUpdated) Then
			InterestScheduleUpdated = False;
		EndIf;
		If Not InterestScheduleUpdated Then
			CalculationParameters = LeasedAssetAccounting.ParametersForCalculatingInterestRatesOfProfitableLeases(ThisObject, ContractDetails_);
			CalculationParameters.OutputMessages = False;
			LeasedAssetAccounting.CalculateInterestRatesOfProfitableRent(CalculationParameters);
			InterestAccrualSchedule.Load(CalculationParameters.InterestAccrualSchedule);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckFixedAssets(Cancel)
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "ContractType, LeaseContracts");
	
	If ContractDetails_.ContractType <> Enums.ContractTypes.Sublease
		And ContractDetails_.ContractType <> Enums.ContractTypes.TransferToRental Then
		Return;
	EndIf;
	
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
	|	AccountingProcedureForOSBUSliceLast.FixedAsset AS FixedAsset
	|INTO TueAccountingProcedureForOSBU
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date,
	|			FixedAsset IN
	|					(SELECT
	|						TTFATable.FixedAsset AS FixedAsset
	|					FROM
	|						TTFATable AS TTFATable)
	|				AND Recorder <> &Ref) AS AccountingProcedureForOSBUSliceLast
	|WHERE
	|	AccountingProcedureForOSBUSliceLast.BUState = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
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
	|		WHEN NOT AccountingProcedureForOSBU.FixedAsset IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FAAcceptedForOffBalanceSheetAccounting,
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
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON FATable.FixedAsset = AccountingProcedureForOSBU.FixedAsset
	|WHERE
	|	(&ThisIsTransferForRent
	|				AND LeasedAsset.State IN (VALUE(Enum.FixedAssetsStates.InLease), VALUE(Enum.FixedAssetsStates.LeaseContractsSigned))
	|			OR NOT AssetsLeasedOut.FixedAsset IS NULL
	|			OR NOT AccountingProcedureForOSBU.FixedAsset IS NULL
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
	MessageTemplateOfFAHasBeenAcceptedForOffBalanceSheetAccounting =
		NStr("vi = 'Trong dòng %1 của danh sách ""Tài sản cố định hữu hình"" đã chỉ ra tài sản cố định hữu hình mà được tiếp nhận vào kế toán ngoại bảng';
			|ru = 'В строке %1 списка ""Основные средства"" указано основное средство, принятое к забалансовому учету';
			|en = 'Line %1 of the ""Fixed assets"" list contains a fixed asset which is entered in off-balance accounting'; fa = 'Line %1 of the ""Fixed assets"" list contains a fixed asset which is entered in off-balance accounting';
			|it = 'В строке %1 списка ""Основные средства"" указано основное средство, принятое к забалансовому учету';
			|pl = 'Line %1 of the ""Fixed assets"" list contains a fixed asset which is entered in off-balance accounting';
			|tr = '""Sabit kıymetler"" listesinin %1 satırında, bilanço dışı muhasebeye kabul edilen sabit kıymet belirtilmektedir'");

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
		
		If Selection.FAAcceptedForOffBalanceSheetAccounting Then
			MessageText = StrTemplate(MessageTemplateOfFAHasBeenAcceptedForOffBalanceSheetAccounting, Selection.LineNumber);
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

#EndRegion

#EndIf

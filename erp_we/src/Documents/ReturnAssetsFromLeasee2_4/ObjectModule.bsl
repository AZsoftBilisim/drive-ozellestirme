#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ProvideAssetsToLeasee2_4") Then
		FillInBasedOnFATransferToTenant(FillingData);
	EndIf;
	
	ReturnAssetsFromLeaseeLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("FA.FixedAssetsAccountingProcedure");
	AttributesNotToCheck.Add("FA.ExpenseItem");
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_FARefundFromLease(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	CheckFixedAssets(AuxiliaryAttributes.ReturnFromFinarenda, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReturnAssetsFromLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	If ValueIsFilled(Organization) And ValueIsFilled(Leaseholder) And (Organization = Leaseholder) Then
		Text = NStr("vi = 'Trường ""Doanh nghiệp"" và ""Người cho thuê"" phải khác nhau.';
					|ru = 'Поля ""Организация"" и ""Арендатор"" должны различаться.';
					|en = 'The ""Company"" and ""Lessee"" fields must be different.'; fa = 'The ""Company"" and ""Lessee"" fields must be different.';
					|it = 'I campi ""Organizzazione"" e ""Locatore"" devono differire tra loro.';
					|pl = 'Pola ""Firma"" i ""Najemca"" powinny różnić się.';
					|tr = '""İş yeri"" ve ""Kiracı"" alanları farklı olmalıdır.'");
		CommonClientServer.MessageToUser(Text, ThisObject, "Leaseholder",, Cancel);
	EndIf;
	
	CheckAvailabilityWithTenant(AuxiliaryAttributes.ReturnFromFinarenda, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	ReturnAssetsFromLeaseeLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	ReturnAssetsFromLeaseeLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ReturnFromFinarenda = ValueIsFilled(Contract);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting
		And Not ReturnFromFinarenda Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		NonCurrentAssetsInternal.FillInReflectionInAccounting(ThisObject, FA.Unload().UnloadColumn("FixedAsset"));
		CheckThatFAHasNotBeenTransferredToFinLease(Cancel);
	EndIf;
	
	If ReturnFromFinarenda Then
		RecordInLocalAccounting = True;
		RecordInManAccounting = True;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
		
	If Not ValueIsFilled(LocationAddress) Then
		LocationAddress = "";
	EndIf;

	ItemsAndDimensionsSelectionParameters = Documents.ReturnAssetsFromLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.ReturnAssetsFromLeasee2_4.AccountingAccountSettings_());

	ReturnAssetsFromLeaseeLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReturnAssetsFromLeaseeLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReturnAssetsFromLeaseeLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReturnAssetsFromLeaseeLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument()
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	ReceivingBusinessUnit = Department;
	
	ItemsAndDimensionsSelectionParameters = Documents.ReturnAssetsFromLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
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
		
		MessageText = NStr("vi = 'Không thể trả lại từ người cho thuê nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên xuống dưới.';
			|ru = 'Возврат от арендатора группы ОС невозможен.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot return fixed assets group from lessee.
			|Select fixed assets. To open the group, press Ctrl and the arrow down.'; fa = 'Cannot return fixed assets group from lessee.
			|Select fixed assets. To open the group, press Ctrl and the arrow down.';
			|it = 'Non è possibile effettuare il reso da parte del locatore del gruppo di immobilizzazioni.
			| Selezionare immobilizzazione. Per aprire il gruppo, utilizzare i tasti Ctrl e la freccia su.';
			|pl = 'Zwrot od dzierżawcy grupy środków trwałych jest niemożliwy.
			|Wybierz środek trwały. Aby otworzyć grupę naciśnij klawisze Ctrl i strzałkę do dołu.';
			|tr = 'Sabit kıymet grupları kiracısından iade mümkün değildir. 
			| Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	FALocation = NonCurrentAssets.FALocation(Basis);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.LeaseholderBusinessUnit;
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
	Else
		If LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts().Find(
				Common.ObjectAttributeValue(Contract, "ContractType")) = Undefined Then
			Contract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
EndProcedure

Procedure FillInBasedOnFATransferToTenant(FillingData)
	
	Query = New Query;
	Query.SetParameter("FillingData", FillingData);
	Query.Text=
	"SELECT
	|	ProvideAssetsToLeasee.Organization AS Organization,
	|	CASE
	|		WHEN ProvideAssetsToLeasee.Contract REFS Catalog.CounterpartyContracts
	|			THEN CASE
	|					WHEN CAST(ProvideAssetsToLeasee.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfProfitableLeaseContracts)
	|						THEN ProvideAssetsToLeasee.Contract
	|					ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				END
	|		ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|	END AS Contract,
	|	ProvideAssetsToLeasee.ReceivingBusinessUnit AS Department,
	|	ProvideAssetsToLeasee.Department AS ReceivingBusinessUnit,
	|	ProvideAssetsToLeasee.LeaseholderIntercompanyARAP AS LeaseholderIntercompanyARAP,
	|	ProvideAssetsToLeasee.Leaseholder AS Leaseholder,
	|	ProvideAssetsToLeasee.Ref AS DocumentBasis,
	|	TRUE AS GeneratedDocument,
	|	ProvideAssetsToLeasee.FA.(
	|		FixedAsset AS FixedAsset
	|	)
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS ProvideAssetsToLeasee
	|WHERE
	|	ProvideAssetsToLeasee.Ref = &FillingData";
	
	Query.SetParameter("TypesOfProfitableLeaseContracts", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	FA.Load(Selection.FA.Unload());
	
EndProcedure

#EndRegion

#Region Other

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
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf; 
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.AccountingProcedureForOSBU");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	Block.Lock(); 
	
EndProcedure

Procedure CheckAvailabilityWithTenant(ReturnFromFinarenda, Cancel)

	If ReturnFromFinarenda
		Or Not ValueIsFilled(Leaseholder)
		Or Not ValueIsFilled(Organization)
		Or Not ValueIsFilled(Department) Then
		Return;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|INTO FATable
	|FROM
	|	&FATable AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.LineNumber AS LineNumber,
	|	CAST(FATable.FixedAsset AS Catalog.Assets).Presentation AS FixedAssetPresentation,
	|	FALocation.Organization AS Organization,
	|	FALocation.Organization.Presentation AS OrganizationPresentation,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|	FALocation.FixedAssetsLocation.Presentation AS FixedAssetsLocationPresentation,
	|	FALocation.Leaseholder AS Leaseholder,
	|	FALocation.Leaseholder.Presentation AS LeaseholderPresentation
	|FROM
	|	FATable AS FATable
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|				&Date,
	|				Recorder <> &Recorder
	|					AND CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN
	|						(SELECT
	|							FATable.FixedAsset
	|						FROM
	|							FATable)) AS FALocation
	|		ON (FALocation.FixedAsset = FATable.FixedAsset)
	|WHERE
	|	(FALocation.Organization <> &Organization
	|			OR FALocation.FixedAssetsLocation <> &Department
	|			OR FALocation.Leaseholder <> &Leaseholder
	|			OR FALocation.FixedAsset IS NULL)
	|
	|ORDER BY
	|	LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Leaseholder", Leaseholder);
	Query.SetParameter("FATable", FA.Unload());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Path = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
		
		If Not ValueIsFilled(Selection.Leaseholder) Then
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được tính là đã chuyển giao vào thuê %2';
								|ru = 'Основное средство ""%1"" не числится переданным в аренду на %2';
								|en = 'Asset ""%1"" are not deemed to be transferred for rental on %2'; fa = 'Asset ""%1"" are not deemed to be transferred for rental on %2';
								|it = 'L''immobilizzazione ""%1"" non rientra tra quelle date in affitto per %2';
								|pl = 'Środek trwały ""%1"" nie liczy się za przekazany do dzierżawy na %2';
								|tr = 'Sabit kıymetler ""%1"" %2''ye kiralanmamıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Format(Date, "DLF=D"));
			
		ElsIf Selection.Organization <> Organization Then
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được chuyển vào thuê từ doanh nghiệp khác ""%2""';
								|ru = 'Основное средство ""%1"" передано в аренду от другой организации ""%2""';
								|en = 'Asset ""%1"" is transferred for rental from other company ""%2""'; fa = 'Asset ""%1"" is transferred for rental from other company ""%2""';
								|it = 'Immobilizzazione ""%1"" data in affitto da parte di un''altra organizzazione ""%2""';
								|pl = 'Środek trwały ""%1"" jest przekazany do dzierżawy od innej firmy ""%2""';
								|tr = '""%1"" sabit kıymeti başka bir ""%2"" iş yeri tarafından kiralanmıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Selection.OrganizationPresentation);
			
		ElsIf Selection.Leaseholder <> Leaseholder Then
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được chuyển vào thuê cho người cho thuê khác ""%2""';
								|ru = 'Основное средство ""%1"" передано в аренду другому арендатору ""%2""';
								|en = 'Asset ""%1"" is transferred for rental to other lessee ""%2""'; fa = 'Asset ""%1"" is transferred for rental to other lessee ""%2""';
								|it = 'Immobilizzazione ""%1"" data in affitto a un altro affittuario ""%2""';
								|pl = 'Środek trwały ""%1"" jest przekazany do dzierżawy do innego najemcy ""%2""';
								|tr = 'Sabit kıymet ""%1"" başka bir ""%2""kuruluşa kiralanmıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Selection.LeaseholderPresentation);
			
		ElsIf Selection.FixedAssetsLocation <> Department Then
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" được liệt kê cho người sử dụng khác ""%2""';
								|ru = 'Основное средство ""%1"" числится за другим подразделением ""%2""';
								|en = 'Asset ""%1"" is registered with the other business unit ""%2""'; fa = 'Asset ""%1"" is registered with the other business unit ""%2""';
								|it = 'L''immobilizzazione ""%1"" è inclusa nell''altra suddivisione ""%2""';
								|pl = 'Środek trwały „%1” jest zapisany na inny dział „%2”';
								|tr = 'Sabit kıymet ""%1"" başka bir departmana ""%2"" atanmıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Selection.FixedAssetsLocationPresentation);
			
		EndIf; 
		
		CommonClientServer.MessageToUser(MessageText, ThisObject, Path,, Cancel);
	
	EndDo;
	
EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	
	AuxiliaryAttributes.Insert(
		"LeaseAccountingAccordingToFSB25_2018IsUsed",
		LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
		
	AuxiliaryAttributes.Insert(
		"ReturnFromFinarenda",
		ValueIsFilled(Contract));
	
	Return AuxiliaryAttributes;
	
EndFunction

Procedure CheckFixedAssets(TransferByFSB25, Cancel)
	
	If Not TransferByFSB25 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure,
	|	FATable.ExpenseItem AS ExpenseItem
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
	|						TTFATable.FixedAsset
	|					FROM
	|						TTFATable AS TTFATable)
	|				AND Recorder <> &Ref) AS AssetsLeasedOutSliceLast
	|WHERE
	|	AssetsLeasedOutSliceLast.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND AssetsLeasedOutSliceLast.Counterparty = &Counterparty
	|	AND AssetsLeasedOutSliceLast.Contract = &Contract
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTFATable.LineNumber AS LineNumber,
	|	TTFATable.FixedAsset AS FixedAsset,
	|	TTLeasedToFA.FixedAsset IS NULL AS NotLeasedOut,
	|	CASE
	|		WHEN TTFATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FAAccountingProcedureIsNotFilledIn,
	|	CASE
	|		WHEN TTFATable.FixedAssetsAccountingProcedure <> VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|				AND (TTFATable.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|					OR TTFATable.ExpenseItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ExpenseItemIsNotFilledIn
	|FROM
	|	TTFATable AS TTFATable
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTFATable.FixedAsset = TTLeasedToFA.FixedAsset
	|WHERE
	|	TTLeasedToFA.FixedAsset IS NULL
	|	OR TTFATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.EmptyRef)
	|	OR (TTFATable.FixedAssetsAccountingProcedure <> VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|		AND (TTFATable.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		OR TTFATable.ExpenseItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)))";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Counterparty", Leaseholder);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FATable", FA.Unload(, "LineNumber,FixedAsset,FixedAssetsAccountingProcedure,ExpenseItem"));
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	MessageTemplateNotLeased =
		NStr("vi = 'Chưa chuyển cho thuê đối tượng kế toán trong dòng %1 của danh sách ""Tài sản cố định"" theo hợp đồng được chọn';
			|ru = 'Объект учета в строке %1 списка ""Основные средства"" не передан в аренду по выбранному договору';
			|en = 'The accounting object in line %1 of the Fixed assets list is not provided to the lessee under the selected contract'; fa = 'The accounting object in line %1 of the Fixed assets list is not provided to the lessee under the selected contract';
			|it = 'Объект учета в строке %1 списка ""Основные средства"" не передан в аренду по выбранному договору';
			|pl = 'The accounting object in line %1 of the Fixed assets list is not provided to the lessee under the selected contract';
			|tr = '""Sabit kıymetler"" listesinin %1 satırındaki muhasebe nesnesi, seçilen sözleşme kapsamında kiralanmadı'");
	MessageTemplateFAAccountingProcedure =
		NStr("vi = 'Chưa điền cột ""Trình tự kế toán TSCĐ"" trong dòng %1 của danh sách ""Tài sản cố định""';
			|ru = 'Не заполнена колонка ""Порядок учета ОС"" в строке %1 списка ""Основные средства""';
			|en = 'The ""Fixed assets accounting procedure"" column is not filled in line %1 of the ""Fixed assets"" list'; fa = 'The ""Fixed assets accounting procedure"" column is not filled in line %1 of the ""Fixed assets"" list';
			|it = 'Не заполнена колонка ""Порядок учета ОС"" в строке %1 списка ""Основные средства""';
			|pl = 'The ""Fixed assets accounting procedure"" column is not filled in line %1 of the ""Fixed assets"" list';
			|tr = '""Sabit kıymetler"" listesinin %1 satırındaki ""Sabit kıymet muhasebe prosedürü"" sütunu doldurulmadı'");
	MessageTemplateExpenseItem
		= NStr("vi = 'Chưa điền cột ""Dạng chi phí"" trong dòng %1 của danh sách ""Tài sản cố định""';
				|ru = 'Не заполнена колонка ""Статья расходов"" в строке %1 списка ""Основные средства""';
				|en = 'The ""Expense item"" column is not filled in line %1 of the ""Fixed assets"" list'; fa = 'The ""Expense item"" column is not filled in line %1 of the ""Fixed assets"" list';
				|it = 'Не заполнена колонка ""Статья расходов"" в строке %1 списка ""Основные средства""';
				|pl = 'The ""Expense item"" column is not filled in line %1 of the ""Fixed assets"" list';
				|tr = '""Sabit kıymetler"" listesinin %1 satırındaki ""Gider kalemi"" sütunu doldurulmadı'");
	
	While Selection.Next() Do
		
		If Selection.NotLeasedOut Then
			MessageText = StrTemplate(MessageTemplateNotLeased, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			Continue;
		EndIf;
		
		If Selection.FAAccountingProcedureIsNotFilledIn Then
			MessageText = StrTemplate(MessageTemplateFAAccountingProcedure, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAssetsAccountingProcedure");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.ExpenseItemIsNotFilledIn Then
			MessageText = StrTemplate(MessageTemplateExpenseItem, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckThatFAHasNotBeenTransferredToFinLease(Cancel)
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	AssetsLeasedOut.FixedAsset AS Ref,
	|	AssetsLeasedOut.FixedAsset.Presentation AS Presentation
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|		&Period, 
	|		Recorder <> &Ref 
	|			AND FixedAsset IN (&ListOfFA)) AS AssetsLeasedOut
	|
	|WHERE
	|	AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND CAST(AssetsLeasedOut.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Date);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	ListOfFA = FA.UnloadColumn("FixedAsset");
		
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được chuyển sang thuê tài chính.
							  |Cần chỉ ra hợp đồng trong chứng từ.';
							  |ru = 'Основное средство ""%1"" было передано в финансовую аренду.
							  |Необходимо указать договор в документе.';
							  |en = 'The ""%1"" fixed asset is transferred to the financial lease.
							  |Specify the contract in the document.'; fa = 'The ""%1"" fixed asset is transferred to the financial lease.
							  |Specify the contract in the document.';
							  |it = 'Основное средство ""%1"" было передано в финансовую аренду.
							  |Необходимо указать договор в документе.';
							  |pl = 'The ""%1"" fixed asset is transferred to the financial lease.
							  |Specify the contract in the document.';
							  |tr = 'Sabit kıymet ""%1"" finansal kiralanmaya aktarıldı.
							  |Sözleşme belgede belirtilmeli.'");
		MessageText = StrTemplate(MessageText, Selection.Presentation);
		
		RowData = FA.Find(Selection.Ref, "FixedAsset");
		Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
		Common.MessageToUser(MessageText, ThisObject, Path,, Cancel);
		
	EndDo;

EndProcedure

#EndRegion

#EndRegion

#EndIf

////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the activity direction for the specified link
//
// Parameters:
// 		Ref - CatalogRef.LeaseContract, CatalogRef.Assets - A link to the reference book that you need to get your business direction from.
//
// Returns:
// 		CatalogRef.LinesOfBusiness - A link to an element of the business directory.
//
Function LineOfBusiness(Ref) Export
	
	ReturnValue = Catalogs.LinesOfBusiness.EmptyRef(); 
	
	If TypeOf(Ref) = Type("CatalogRef.LeaseContract") Then
		
		ReturnValue = Common.ObjectAttributeValue(Ref, "LineOfBusiness");
	
	ElsIf TypeOf(Ref) = Type("CatalogRef.Assets") Then

		QueryText = 
		"SELECT
		|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(, FixedAsset = &FixedAsset) AS FixedAssetsAccountingProcedure";
		
		Query = New Query(QueryText);
		Query.SetParameter("FixedAsset", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			ReturnValue = Selection.LineOfBusiness;
		EndIf;
		
	EndIf;	
	
	Return ?(ValueIsFilled(ReturnValue), ReturnValue, Catalogs.LinesOfBusiness.EmptyRef());
	
EndFunction

// Generates data for selecting fixed assets.
//
// Parameters:
//  Parameters			 - Structure - contains settings for the choice.
//  StandardProcessing - Boolean - The event parameter of Obrabatyvaniya.
// 
// Returns:
//  ValueList - Values to select.
//
Function DataSelectionOfObjectsOfOperation(Parameters, StandardProcessing) Export

	ChoiceData = Undefined;
	
	If NonCurrentAssetsInternal.AvailableSelectionOfObjectsOfOperation2_4(Parameters) Then
		StandardProcessing = False;
		ChoiceData = DataSelectionOfObjectsOfOperation2_4(Parameters);
	Else
		NonCurrentAssetsLocalization.DataSelectionOfObjectsOfOperation2_2(Parameters);
	EndIf;
	
	Return ChoiceData;

EndFunction

// Generates data for selecting intangible assets.
//
// Parameters:
//  Parameters			 - Structure - contains settings for the choice.
//  StandardProcessing - Boolean - The event parameter of Obrabatyvaniya.
// 
// Returns:
//  ValueList - Values to select.
//
Function IntangibleAssetSelectionData(Parameters, StandardProcessing) Export

	ChoiceData = Undefined;
	
	If SelectionOfIntangibleAssets2_4IsAvailable(Parameters) Then
		StandardProcessing = False;
		ChoiceData = IntangibleAssetSelectionData2_4(Parameters);
	Else
		NonCurrentAssetsLocalization.IntangibleAssetSelectionData2_2(Parameters);
	EndIf;
	
	Return ChoiceData;

EndFunction

#Region SelectionsBasedOnAccountingData

// Returns a list of the values of the operating time indicators that belong to the operation object class.
//
// Parameters:
// 		FilterObject - CatalogRef.Assets, CatalogRef.SubAssets, CatalogRef.MaintenanceSchemes - Selection object
// 		GetSourcesOfRunningTime - Boolean - Indicates whether it is necessary to get indicators registered from the source
// 		DepreciationIndicator - CatalogRef.RunningTimeValues - Current value.
//
// Returns:
// 		ValueList - List of selection data.
//
Function DataOnSelectionOfOperatingTimeIndicatorsForSelection(Val FilterObject, GetSourcesOfRunningTime, DepreciationIndicator) Export
	
	ChoiceData = New ValueList;
	
	ListOfRequests = New Array;
	QueryText =
	"SELECT ALLOWED
	|	&FilterObject AS Class
	|INTO Classes
	|WHERE
	|	&UseRMManagement
	|
	|UNION ALL
	|
	|SELECT
	|	Objects.Class
	|FROM
	|	Catalog.Assets AS Objects
	|WHERE
	|	Objects.Ref = &FilterObject
	|	AND &UseRMManagement
	|
	|UNION ALL
	|
	|SELECT
	|	Nodes.Class
	|FROM
	|	Catalog.SubAssets AS Nodes
	|WHERE
	|	Nodes.Ref = &FilterObject
	|	AND &UseRMManagement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	RunningTimeValues.RunningTimeValue AS RunningTimeValue,
	|	RunningTimeValues.RegisterBySource AS RegisterBySource
	|INTO Indicators
	|FROM
	|	Catalog.MaintenanceSchemes.RunningTimeValues AS RunningTimeValues
	|WHERE
	|	RunningTimeValues.Ref IN
	|			(SELECT
	|				Classes.Class
	|			FROM
	|				Classes)
	|	AND CASE
	|			WHEN &GetSourcesOfRunningTime
	|				THEN NOT RunningTimeValues.RegisterBySource
	|			ELSE TRUE
	|		END";
	ListOfRequests.Add(QueryText);
	ListOfMergeRequests = New Array;
	
	QueryText =
	"SELECT ALLOWED
	|	FixedAssetsAccountingProcedure.RunningTimeValue AS Value,
	|	FixedAssetsAccountingProcedure.RunningTimeValue.DeletionMark AS DeletionMark
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|			,
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND FixedAsset = &FilterObject
	|				AND NOT RunningTimeValue IN
	|						(SELECT
	|							Indicators.RunningTimeValue
	|						FROM
	|							Indicators AS Indicators)
	|	) AS FixedAssetsAccountingProcedure
	|WHERE
	|	NOT &DepreciationIndicator
	|	AND FixedAssetsAccountingProcedure.RunningTimeValue <> VALUE(Catalog.RunningTimeValues.EmptyRef)";
	ListOfMergeRequests.Add(QueryText);
	QueryText =
	"SELECT
	|	Indicators.RunningTimeValue,
	|	Indicators.RunningTimeValue.DeletionMark
	|FROM
	|	Indicators AS Indicators
	|WHERE
	|	CASE
	|			WHEN &GetSourcesOfRunningTime
	|				THEN NOT Indicators.RegisterBySource
	|			ELSE TRUE
	|		END";
	ListOfMergeRequests.Add(QueryText);
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.SetParameter("FilterObject", FilterObject);
	Query.SetParameter("GetSourcesOfRunningTime", GetSourcesOfRunningTime);
	Query.SetParameter("DepreciationIndicator", DepreciationIndicator);
	Query.SetParameter("UseRMManagement", GetFunctionalOption("UseRMManagement"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return ChoiceData;
	EndIf;
	
	TemplateStructureFields = "Value, DeletionMark";
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		ElementStructure = New Structure(TemplateStructureFields);
		FillPropertyValues(ElementStructure, Selection);
		ChoiceData.Add(ElementStructure);
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function SelectionOfIntangibleAssets2_4IsAvailable(Parameters) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return False;
	EndIf;
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
		Return True;
	EndIf;
	
	AccountingStartDate = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	ChoiceAvailable = 
		Parameters.Property("Context") 
			And StrFind(Parameters.Context, "MA") <> 0 
		Or Not Parameters.Property("DateOfLastEdit")
			And CurrentSessionDate() >= AccountingStartDate 
		Or Parameters.Property("DateOfLastEdit")
			And Parameters.DateOfLastEdit >= AccountingStartDate;
			
	If Not ChoiceAvailable Then
		Return False;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Busstate") Then
			Parameters.Filter.Insert("State", Parameters.Filter.Busstate);
		EndIf; 
		If Parameters.Filter.Property("Buorganization") Then
			Parameters.Filter.Insert("Organization", Parameters.Filter.Buorganization);
		EndIf; 
		If Parameters.Filter.Property("Bupodispartion") Then
			Parameters.Filter.Insert("Department", Parameters.Filter.Bupodispartion);
		EndIf; 
	EndIf; 
	
	Return True;

EndFunction
 
Function OperationOfEnteringBalances(DocumentRef) Export

	If Not ValueIsFilled(DocumentRef) Then
		Return Undefined;
	EndIf; 
	
	Return Common.ObjectAttributeValue(DocumentRef, "BusinessOperation");
	
EndFunction

Function PresentationOfInputBalances(Object) Export
	
	If TypeOf(Object) = Type("Structure") 
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectAttributes = Object;
	Else	
		ObjectAttributes = Common.ObjectAttributesValues(Object, "Ref, Number, Date, BusinessOperation");
	EndIf; 
	
	If Not ValueIsFilled(ObjectAttributes.BusinessOperation) Then
		Return "";
	EndIf;
	
	PresentationNumberDate = NStr("vi = '(tạo)';
									|ru = '(создание)';
									|en = '(Create)'; fa = '(Create)';
									|it = '(creazione)';
									|pl = '(utworzenie)';
									|tr = '(oluştur)'");
	If ValueIsFilled(ObjectAttributes.Ref) Then
		PresentationNumberDate = StrTemplate(NStr("vi = '%1 ngày %2';
													|ru = '%1 от %2';
													|en = '%1 dated %2'; fa = '%1 dated %2';
													|it = '%1 del %2';
													|pl = '%1 z dn. %2';
													|tr = '%2 itibarıyla %1'"), ObjectAttributes.Number, ObjectAttributes.Date);
	EndIf;
	
	Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản dài hạn %1';
						|ru = 'Ввод начальных остатков внеоборотных активов %1';
						|en = 'OB entry: Fixed asset cost and depreciation %1'; fa = 'OB entry: Fixed asset cost and depreciation %1';
						|it = 'Inserimento dei saldi iniziali degli attivi non circolanti %1';
						|pl = 'Wprowadzenie sald początkowych aktywów pozaobrotowych %1';
						|tr = 'Duran varlıkların açılış bakiyelerinin girişi %1'");
	
	If ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản cố định %1';
							|ru = 'Ввод начальных остатков основных средств %1';
							|en = 'OB entry: cost of owned fixed assets %1'; fa = 'OB entry: cost of owned fixed assets %1';
							|it = 'Inserimento dei saldi iniziali dei capitali fissi %1';
							|pl = 'Wprowadzenie sald początkowych środków trwałych %1';
							|tr = 'Sabit kıymetlerin açılış bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản cố định cho thuê %1';
							|ru = 'Ввод начальных остатков переданных в аренду основных средств %1';
							|en = 'OB entry: leased out fixed assets %1'; fa = 'OB entry: leased out fixed assets %1';
							|it = 'Inserimento dei saldi iniziali dei capitali fissi dati in affitto %1';
							|pl = 'Wprowadzenie sald początkowych przekazanych do dzierżawy środków trwałych %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		Presentation = NStr("vi = 'Nhập số dư đầu Tài sản cố định vô hình và Chi phí Nghiên cứu và phát triển %1';
							|ru = 'Ввод начальных остатков НМА и расходов на НИОКР %1';
							|en = 'OB entry: cost of owned intangible assets %1'; fa = 'OB entry: cost of owned intangible assets %1';
							|it = 'Inserimento dei saldi iniziali dei beni immateriali e delle spese in Ricerca & Sviluppo %1';
							|pl = 'Wprowadzenie sald początkowych wartości niematerialnych i rozchodów na R&D %1';
							|tr = 'GMA ve Ar-Ge%1 giderleri başlangıç bakiyelerinin girilmesi'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryLeaseContractsARAP Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu hạch toán công nợ theo hợp đồng thuê tài chính %1';
							|ru = 'Ввод начальных остатков взаиморасчетов по договорам аренды %1';
							|en = 'OB entry: AR/AP under rental contracts %1'; fa = 'OB entry: AR/AP under rental contracts %1';
							|it = 'Inserimento dei saldi iniziali dei conti reciproci in base ai contratti di affitto%1';
							|pl = 'Wprowadzenie sald początkowych rozliczeń wzajemnych w ramach umów dzierżawy %1';
							|tr = 'Kira sözleşmeleri kapsamında karşılıklı ödemelerin başlangıç bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets Then
		Presentation = NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (trong bảng cân đối) %1';
							|ru = 'Ввод начальных остатков арендованных ОС (на балансе) %1';
							|en = 'OB entry: leased fixed assets (on balance sheet) %1'; fa = 'OB entry: leased fixed assets (on balance sheet) %1';
							|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (in bilancio)%1';
							|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (na bilansie) %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bilançoda) %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets Then
		Presentation = NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (ngoài bảng cân đối) %1';
							|ru = 'Ввод начальных остатков арендованных ОС (за балансом) %1';
							|en = 'OB entry: leased fixed assets (off balance sheet) %1'; fa = 'OB entry: leased fixed assets (off balance sheet) %1';
							|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (fuori bilancio)%1';
							|pl = 'Wprowadzenie sald początkowych środków trwałych (poza bilansem) %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girişi (bilanço dışı) %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê ngoài bảng %1';
							|ru = 'Ввод начальных остатков предметов лизинга за балансом %1';
							|en = 'OB entry: financial lease items off the balance sheet %1'; fa = 'OB entry: financial lease items off the balance sheet %1';
							|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio %1';
							|pl = 'Wprowadzenie sald początkowych przedmiotów leasingu poza bilansem %1';
							|tr = 'Bilanço dışı kiralanan kalemlerin başlangıç bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê trong bảng  %1';
							|ru = 'Ввод начальных остатков переданных в аренду предметов лизинга на балансе %1';
							|en = 'OB entry: financial lease items on the balance sheet %1'; fa = 'OB entry: financial lease items on the balance sheet %1';
							|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio dati in affitto %1';
							|pl = 'Wprowadzenie początkowych sald przekazanych do dzierżawy przedmiotów leasingu na bilansie %1';
							|tr = 'Kiralanan kalemlerin başlangıç bakiyelerinin bilançoya girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets Then
		Presentation = NStr("vi = 'Nhập số dư đầu tư ban đầu vào tài sản dài hạn %1';
							|ru = 'Ввод начальных остатков вложений во внеоборотные активы %1';
							|en = 'OB entry: investments in fixed and intangible assets %1'; fa = 'OB entry: investments in fixed and intangible assets %1';
							|it = 'Inserimento dei saldi iniziali degli investimenti in attivi non circolanti %1';
							|pl = 'Wprowadzenie sald początkowych inwestycji w aktywa stałe %1';
							|tr = 'Duran varlıklara yapılan yatırımların başlangıç bakiyelerinin girişi %1'");
	EndIf;
	
	Return StrTemplate(Presentation, PresentationNumberDate);
	
EndFunction

Function PresentationOfInputBalances2_2(Object) Export
	
	If TypeOf(Object) = Type("Structure") 
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectAttributes = Object;
	Else	
		ObjectAttributes = Common.ObjectAttributesValues(Object, "Ref, Number, Date, BusinessOperation");
	EndIf; 
	
	If Not ValueIsFilled(ObjectAttributes.BusinessOperation) Then
		Return "";
	EndIf;
	
	PresentationNumberDate = NStr("vi = '(tạo)';
									|ru = '(создание)';
									|en = '(Create)'; fa = '(Create)';
									|it = '(creazione)';
									|pl = '(utworzenie)';
									|tr = '(oluştur)'");
	If ValueIsFilled(ObjectAttributes.Ref) Then
		PresentationNumberDate = StrTemplate(NStr("vi = '%1 ngày %2';
													|ru = '%1 от %2';
													|en = '%1 dated %2'; fa = '%1 dated %2';
													|it = '%1 del %2';
													|pl = '%1 z dn. %2';
													|tr = '%2 itibarıyla %1'"), ObjectAttributes.Number, ObjectAttributes.Date);
	EndIf;
	
	Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản dài hạn  %1';
						|ru = 'Ввод начальных остатков внеоборотных активов %1';
						|en = 'OB entry: Fixed asset cost and depreciation %1'; fa = 'OB entry: Fixed asset cost and depreciation %1';
						|it = 'Inserimento dei saldi iniziali degli attivi non circolanti %1';
						|pl = 'Wprowadzenie sald początkowych aktywów pozaobrotowych %1';
						|tr = 'Duran varlıkların açılış bakiyelerinin girişi %1'");
	If ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryFixedAssets") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản cố định  %1';
							|ru = 'Ввод начальных остатков основных средств %1';
							|en = 'OB entry: cost of owned fixed assets %1'; fa = 'OB entry: cost of owned fixed assets %1';
							|it = 'Inserimento dei saldi iniziali dei capitali fissi %1';
							|pl = 'Wprowadzenie sald początkowych środków trwałych %1';
							|tr = 'Sabit kıymetlerin açılış bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của tài sản cố định cho thuê  %1';
							|ru = 'Ввод начальных остатков переданных в аренду основных средств %1';
							|en = 'OB entry: leased out fixed assets %1'; fa = 'OB entry: leased out fixed assets %1';
							|it = 'Inserimento dei saldi iniziali dei capitali fissi dati in affitto %1';
							|pl = 'Wprowadzenie sald początkowych przekazanych do dzierżawy środków trwałych %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của Tài sản cố định vô hình và Chi phí Nghiên cứu và phát triển %1';
							|ru = 'Ввод начальных остатков нематериальных активов и расходов на НИОКР %1';
							|en = 'OB entry: intangible assets and R&D expenses %1'; fa = 'OB entry: intangible assets and R&D expenses %1';
							|it = 'Inserimento dei saldi iniziale dei beni immateriali e delle spese in Ricerca & Sviluppo %1';
							|pl = 'Wprowadzenie sald początkowych wartości niematerialnych i rozchodów na R&D %1';
							|tr = 'Maddi olmayan varlıkların ve Ar-Ge harcamalarının açılış bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryLeaseContractsARAP") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của các khoản khấu trừ theo hợp đồng thuê tài chính %1';
							|ru = 'Ввод начальных остатков взаиморасчетов по договорам лизинга %1';
							|en = 'OB entry: AR/AP under financial lease contracts %1'; fa = 'OB entry: AR/AP under financial lease contracts %1';
							|it = 'Inserimento dei saldi iniziali dei conti reciproci in base ai contratti di leasing %1';
							|pl = 'Wprowadzenie sald początkowych rozliczeń wzajemnych według umów leasingu %1';
							|tr = 'Finansal kiralama sözleşmeleri kapsamında karşılıklı ödemelerin başlangıç bakiyelerinin girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets") Then
		Presentation = NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (trong bảng cân đối) %1';
							|ru = 'Ввод начальных остатков арендованных ОС (на балансе) %1';
							|en = 'OB entry: leased fixed assets (on balance sheet) %1'; fa = 'OB entry: leased fixed assets (on balance sheet) %1';
							|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (in bilancio)%1';
							|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (na bilansie) %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bilançoda) %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets") Then
		Presentation = NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (ngoài bảng cân đối) %1';
							|ru = 'Ввод начальных остатков арендованных ОС (за балансом) %1';
							|en = 'OB entry: leased fixed assets (off balance sheet) %1'; fa = 'OB entry: leased fixed assets (off balance sheet) %1';
							|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (fuori bilancio)%1';
							|pl = 'Wprowadzenie sald początkowych środków trwałych (poza bilansem) %1';
							|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girişi (bilanço dışı) %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê trong bảng %1';
							|ru = 'Ввод начальных остатков переданных в аренду предметов лизинга на балансе %1';
							|en = 'OB entry: financial lease items on the balance sheet %1'; fa = 'OB entry: financial lease items on the balance sheet %1';
							|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio dati in affitto %1';
							|pl = 'Wprowadzenie początkowych sald przekazanych do dzierżawy przedmiotów leasingu na bilansie %1';
							|tr = 'Kiralanan kalemlerin başlangıç bakiyelerinin bilançoya girişi %1'");
	ElsIf ObjectAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut") Then
		Presentation = NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê ngoài bảng  %1';
							|ru = 'Ввод начальных остатков предметов лизинга за балансом %1';
							|en = 'OB entry: financial lease items off the balance sheet %1'; fa = 'OB entry: financial lease items off the balance sheet %1';
							|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio %1';
							|pl = 'Wprowadzenie sald początkowych przedmiotów leasingu poza bilansem %1';
							|tr = 'Bilanço dışı kiralanan kalemlerin başlangıç bakiyelerinin girişi %1'");
	EndIf;
	
	Return StrTemplate(Presentation, PresentationNumberDate);
	
EndFunction

Function OrganizationsAreInterconnectedByOrganizationalStructure(Val CompanyRecipient, Val Organization) Export

	Return Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(CompanyRecipient, Organization);

EndFunction

Function OrganizationIsInterconnectedWithOtherOrganizations(Val Organization) Export

	Return Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization); 

EndFunction

Function VNAManagementIsUsed_2_4(Period = '000101010000') Export

	Return NonCurrentAssets.VNAManagementIsUsed_2_4(Period);

EndFunction
 
Function FormReceiptProcessing_ObjectsOfOperation(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	Return AssetsLocalization.FormGetProcessing(
				FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndFunction

#EndRegion

#Region Private

// Finds nodes of operational objects by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
// 
// Returns:
//  See NonCurrentAssets.FindObjectsByBarcodes
//
Function FindObjectsOfOperationByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export

	Return NonCurrentAssets.FindObjectsByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

Function DataSelectionOfObjectsOfOperation2_4(Parameters)

	ChoiceData = New ValueList();

	RightsSettings = New Structure;
	
	RightsSettings.Insert(
		"ThereIsRightToRead_LocationOfFA", 
		AccessRight("Read", Metadata.InformationRegisters.FALocation));

	RightsSettings.Insert(
		"ThereIsRightToRead_OrderOfAccountingOfOSU", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSBUAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU));

	RightsSettings.Insert(
		"ThereIsRightToRead_FAAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedure));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSUUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_OSBUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.OSBUDepreciationParameters));

	RightsSettings.Insert(
		"ThereIsRightToRead_InitialFAInformation", 
		AccessRight("Read", Metadata.InformationRegisters.InitialFixedAssetsInformation));

	RightsSettings.Insert(
		"ThereIsRightToRead_RentedFA", 
		AccessRight("Read", Metadata.InformationRegisters.LeasedAsset));

	ChoiceParameters = Catalogs.Assets.GetChoiceParameters(Parameters, RightsSettings);
	DescriptionOfSelectionRequest = Catalogs.Assets.DescriptionOfItemSelectionRequest(ChoiceParameters, RightsSettings, False, True);
	
	If DescriptionOfSelectionRequest.RequiredTables.Count() <> 0 Then
	
		ListOfRequests = New Array();
		
		QueryText =
		"SELECT ALLOWED
		|	CatalogData.Ref AS Ref,
		|	CatalogData.Description AS Description,
		|	CatalogData.AssetID AS AssetID,
		|	CatalogData.OSGroup AS OSGroup,
		|	CatalogData.FixedAssetsGroupFinancialAccounting AS FixedAssetsGroupFinancialAccounting,
		|	CatalogData.OSType AS OSType,
		|	CatalogData.DateOfProduction AS DateOfProduction,
		|	CatalogData.DateOfLastEdit AS DateOfLastEdit,
		|	CatalogData.ManufaturerNumber AS ManufaturerNumber,
		|	CatalogData.RegisteredInPlatonSystemRegistry AS RegisteredInPlatonSystemRegistry,
		|	CatalogData.Manufacturer_ AS Manufacturer_,
		|	CatalogData.Class AS Class,
		|	CatalogData.Subclass AS Subclass,
		|	CatalogData.CodeByRNCFA AS CodeByRNCFA,
		|	CatalogData.Model AS Model,
		|	CatalogData.PassportNumber AS PassportNumber,
		|	CatalogData.HouseholdObject AS HouseholdObject,
		|	CatalogData.OperatingBusinessUnit AS OperatingBusinessUnit,
		|	CatalogData.RMBusinessUnit AS RMBusinessUnit,
		|	CatalogData.SerialNumber AS SerialNumber,
		|	CatalogData.PayrollExpensesPostingMethod AS PayrollExpensesPostingMethod,
		|	CatalogData.Status AS Status,
		|	CatalogData.CodeByUFADR AS CodeByUFADR,
		|	CatalogData.ConsiderResidualLiabilityValue AS ConsiderResidualLiabilityValue
		|
		|INTO TTFAList
		|
		|FROM
		|	Catalog.Assets AS CatalogData
		|
		|WHERE
		|	(CatalogData.Description LIKE &SearchSubstring
		|			OR CatalogData.AssetID LIKE &SearchSubstring)
		|	AND NOT CatalogData.IsFolder
		|	AND NOT CatalogData.DeletionMark
		|
		|INDEX BY
		|	Ref
		|";
		ListOfRequests.Add(QueryText);
		
		JoinText = "";
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FALocation") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.FixedAssetsLocation AS FixedAssetsLocation,
			|	RegisterData.LocationAddress AS LocationAddress,
			|	RegisterData.FinanciallyLiablePerson AS FinanciallyLiablePerson,
			|	RegisterData.Leaseholder AS Leaseholder
			|
			|INTO FALocation
			|
			|FROM
			|	InformationRegister.FALocation.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref 
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);
			
			JoinText = JoinText + "
			|		LEFT JOIN FALocation AS FALocation
			|		ON FALocation.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("InitialFixedAssetsInformation") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.CommissioningDateAC AS CommissioningDateAC,
			|	RegisterData.CommissioningDateTA AS CommissioningDateTA,
			|	RegisterData.CommissioningDateMA AS CommissioningDateMA,
			|	RegisterData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
			|	RegisterData.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
			|	RegisterData.Counterparty AS Counterparty
			|
			|INTO InitialFixedAssetsInformation
			|
			|FROM
			|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
			|		ON InitialFixedAssetsInformation.Organization = FALocation.Organization
			|			AND InitialFixedAssetsInformation.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedureManagementAccounting") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.State AS State
			|
			|INTO FixedAssetsAccountingProcedureManagementAccounting
			|
			|FROM
			|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
			|		ON FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization
			|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("AccountingProcedureForOSBU") Then
			
			QueryText = 
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.BUState AS BUState,
			|	RegisterData.StateTa AS StateTa,
			|	RegisterData.DepreciationGroup AS DepreciationGroup,
			|	RegisterData.RealEstate AS RealEstate,
			|	RegisterData.VATTaxation AS VATTaxation
			|
			|INTO AccountingProcedureForOSBU
			|
			|FROM
			|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
			|		ON AccountingProcedureForOSBU.Organization = FALocation.Organization
			|			AND AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
	
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetDepreciationParametersManagementAccounting") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.UsefulLifeMonths AS UsefulLifeMonths,
			|	RegisterData.DepreciationMethod AS DepreciationMethod
			|
			|INTO FixedAssetDepreciationParametersManagementAccounting
			|
			|FROM
			|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
			|		ON FixedAssetDepreciationParametersManagementAccounting.Organization = FALocation.Organization
			|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("OSBUDepreciationParameters") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
			|	RegisterData.UsefulLifeMonthsTA AS UsefulLifeMonthsTA
			|
			|INTO OSBUDepreciationParameters
			|
			|FROM
			|	InformationRegister.OSBUDepreciationParameters.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND (Organization, FixedAsset) IN (
			|					SELECT 
			|						FALocation.Organization,  
			|						FALocation.FixedAsset  
			|					FROM 
			|						FALocation AS FALocation)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
			|		ON OSBUDepreciationParameters.Organization = FALocation.Organization
			|			AND OSBUDepreciationParameters.FixedAsset = FALocation.FixedAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("FixedAssetsAccountingProcedure") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
			|	RegisterData.LineOfBusiness AS LineOfBusiness
			|
			|INTO FixedAssetsAccountingProcedure
			|
			|FROM
			|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND CorrectionDate = DATETIME(1,1,1)
			|				AND FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref  
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure
			|		ON FixedAssetsAccountingProcedure.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("LeasedAsset") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.FixedAsset AS FixedAsset,
			|	RegisterData.Partner AS Partner,
			|	RegisterData.Counterparty AS Counterparty,
			|	RegisterData.Contract AS Contract
			|
			|INTO LeasedAsset
			|
			|FROM
			|	InformationRegister.LeasedAsset.SliceLast(
			|			&DateOfLastEdit,
			|			FixedAsset IN (
			|					SELECT 
			|						TTFAList.Ref  
			|					FROM 
			|						TTFAList AS TTFAList)) AS RegisterData
			|
			|INDEX BY
			|	FixedAsset
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN LeasedAsset AS LeasedAsset
			|		ON LeasedAsset.FixedAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
	
		QueryText =
		"SELECT ALLOWED TOP 10
		|	CatalogDataOverridable.Ref AS Ref,
		|	CatalogDataOverridable.Description AS Description,
		|	CatalogDataOverridable.AssetID AS AssetID
		|
		|FROM
		|	TTFAList AS CatalogDataOverridable
		|";
		
		If ValueIsFilled(JoinText) Then
			QueryText = QueryText + Chars.LF + JoinText;
		EndIf;

		ListOfRequests.Add(QueryText);
		
		QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
		
		TextSelections = "";

	Else
		
		QueryText =		
		"SELECT ALLOWED TOP 10
		|	CatalogDataOverridable.Ref AS Ref,
		|	CatalogDataOverridable.Description AS Description,
		|	CatalogDataOverridable.AssetID AS AssetID
		|
		|FROM	
		|	Catalog.Assets AS CatalogDataOverridable
		|";
		
		TextSelections = 
		"WHERE
		|	(CatalogDataOverridable.Description LIKE &SearchSubstring
		|			OR CatalogDataOverridable.AssetID LIKE &SearchSubstring)
		|	AND NOT CatalogDataOverridable.IsFolder
		|	AND NOT CatalogDataOverridable.DeletionMark
		|";
		
	EndIf;

	If Not IsBlankString(DescriptionOfSelectionRequest.TextSelections) Then
		TextAnd = "AND"; // @query-part-1
		WhereText = "WHERE"; // @query-part-1
		TextSelections = TextSelections
			+ ?(TextSelections <> "", Chars.LF + TextAnd, WhereText) + Chars.LF + DescriptionOfSelectionRequest.TextSelections; 
	EndIf;
	
	If Not IsBlankString(TextSelections) Then
		QueryText = QueryText + Chars.LF + TextSelections;
	EndIf;
	
	QueryText = QueryText + 
	"
	|ORDER BY
	|	Description
	|";
	
	SliceParametersOfLast_Period = "";
	ParametersOfRecent_CorrectionDate = "TRUE";
	ParametersOfSliceOfLast_Conditions = "TRUE";
	SliceParameters_Registration = "TRUE";
	
	If ChoiceParameters.Property("DateOfLastEdit") Then
		SliceParametersOfLast_Period = "&DateOfLastEdit";
		ParametersOfRecent_CorrectionDate = "CorrectionDate = DATETIME(1,1,1)";
	EndIf; 
	
	If ChoiceParameters.Property("CurrentRegistrar") Then
		ParametersOfSliceOfLast_Conditions = "Recorder <> &CurrentRegistrar";
	EndIf; 

	If ChoiceParameters.Property("ThereAreParametersForCalculatingTransportTax")
			And ChoiceParameters.ThereAreParametersForCalculatingTransportTax
		Or ChoiceParameters.Property("ThereAreParametersForCalculatingLandTax")
			And ChoiceParameters.ThereAreParametersForCalculatingLandTax Then
		
		SliceParameters_Registration = ParametersOfSliceOfLast_Conditions;
		
		If ChoiceParameters.Filter.Property("Organization")
			And ValueIsFilled(ChoiceParameters.Filter.Organization) Then
			
			SliceParameters_Registration = 
				SliceParameters_Registration 
				+ ?(SliceParameters_Registration <> "", " And ", "")
				+ "Organization = &Organization";
				
		EndIf; 
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	QueryText = StrReplace(QueryText, "&PARAMETERS_LAST_CorrectionDate", ParametersOfRecent_CorrectionDate);
	QueryText = StrReplace(QueryText, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	QueryText = StrReplace(QueryText, "&PARAMETERS_LAST_REFERENCES", SliceParameters_Registration);
		
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("SearchSubstring", "%" + Parameters.SearchString + "%");
	Query.SetParameter("DateOfLastEdit", ?(ChoiceParameters.Property("DateOfLastEdit"), EndOfDay(ChoiceParameters.DateOfLastEdit), '00010101'));
	
	For Each ParameterDetails In DescriptionOfSelectionRequest.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;

	If ChoiceParameters.Property("CurrentRegistrar") Then
		Query.SetParameter("CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
	EndIf; 
	
	If ChoiceParameters.Filter.Property("State") Then
		
		FilterValue = NonCurrentAssetsInternal.ValueToArray(ChoiceParameters.Filter.State);
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", Not ValueIsFilled(FilterValue));
		
	Else			
		
		FilterValue = New Array;
		FilterValue.Add(Enums.FixedAssetsStates.EmptyRef());
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", True);
		
	EndIf;

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.AssetID) Then
			Presentation = StrTemplate(NStr("vi = '%1 (số  %2)';
											|ru = '%1 (инв.№ %2)';
											|en = '%1 (inv. No. %2)'; fa = '%1 (inv. No. %2)';
											|it = '%1 (inventario № %2)';
											|pl = '%1 (nr. inw. %2)';
											|tr = '%1 (env. No %2)'"), TrimAll(Selection.Description), TrimAll(Selection.AssetID));
		Else
			Presentation = TrimAll(Selection.Description);
		EndIf;
		
		Presentation = TMCommonUse.PresentationOfSearchResultsByString(Presentation, Parameters.SearchString);
		ChoiceData.Add(Selection.Ref, Presentation);
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction

Function IntangibleAssetSelectionData2_4(Parameters)

	ChoiceData = New ValueList();

	RightsSettings = New Structure;
	
	RightsSettings.Insert(
		"ThereIsRightToRead_PlaceOfIARegistration", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace));

	RightsSettings.Insert(
		"ThereIsRightToRead_AccountingProcedureNMAUU", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_NMABUAccountingProcedure", 
		AccessRight("Read", Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_AccountingProcedureForIA", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure));

	RightsSettings.Insert(
		"ThereIsRightReading_DepreciationParametersNMAUU", 
		AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting));

	RightsSettings.Insert(
		"ThereIsRightReading_NMABUDepreciationParameters", 
		AccessRight("Read", Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting));

	RightsSettings.Insert(
		"ThereIsRightToRead_InitialInformationIA", 
		AccessRight("Read", Metadata.InformationRegisters.InitialIntangibleAssetsInformation));

	ChoiceParameters = Catalogs.IntangibleAssets.GetChoiceParameters(Parameters, RightsSettings);
	DescriptionOfSelectionRequest = Catalogs.IntangibleAssets.DescriptionOfItemSelectionRequest(ChoiceParameters, RightsSettings, False, True);
	
	If DescriptionOfSelectionRequest.RequiredTables.Count() <> 0 Then
	
		ListOfRequests = New Array();
		
		QueryText =
		"SELECT ALLOWED
		|	CatalogData.Ref AS Ref,
		|	CatalogData.Description AS Description,
		|	CatalogData.DescriptionFull AS DescriptionFull,
		|	CatalogData.IntangibleAssetGroup AS IntangibleAssetGroup,
		|	CatalogData.IntangibleAssetsKind AS IntangibleAssetsKind,
		|	CatalogData.KindOfAccountingObject AS KindOfAccountingObject,
		|	CatalogData.DepreciationGroup AS DepreciationGroup
		|
		|INTO TTListOfIa
		|
		|FROM
		|	Catalog.IntangibleAssets AS CatalogData
		|
		|WHERE
		|	CatalogData.Description LIKE &SearchSubstring
		|	AND NOT CatalogData.IsFolder
		|	AND NOT CatalogData.DeletionMark
		|
		|INDEX BY
		|	Ref
		|";
		ListOfRequests.Add(QueryText);
		
		JoinText = "";
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsRegistrationPlace") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.Department AS Department
			|
			|INTO IntangibleAssetsRegistrationPlace
			|
			|FROM
			|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND IntangibleAsset IN (
			|					SELECT 
			|						TTListOfIa.Ref 
			|					FROM 
			|						TTListOfIa AS TTListOfIa)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);
			
			JoinText = JoinText + "
			|		LEFT JOIN IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace
			|		ON IntangibleAssetsRegistrationPlace.IntangibleAsset = CatalogDataOverridable.Ref
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("InitialIntangibleAssetsInformation") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
			|	RegisterData.DateOfRecognitionInTaxAccounting AS DateOfRecognitionInTaxAccounting,
			|	RegisterData.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
			|	RegisterData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
			|	RegisterData.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting
			|
			|INTO InitialIntangibleAssetsInformation
			|
			|FROM
			|	InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND (Organization, IntangibleAsset) IN (
			|					SELECT 
			|						IntangibleAssetsRegistrationPlace.Organization,  
			|						IntangibleAssetsRegistrationPlace.IntangibleAsset  
			|					FROM 
			|						IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
			|		ON InitialIntangibleAssetsInformation.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND InitialIntangibleAssetsInformation.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsAccountingProcedureManagementAccounting") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.State AS State
			|
			|INTO IntangibleAssetsAccountingProcedureManagementAccounting
			|
			|FROM
			|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND (Organization, IntangibleAsset) IN (
			|					SELECT 
			|						IntangibleAssetsRegistrationPlace.Organization,  
			|						IntangibleAssetsRegistrationPlace.IntangibleAsset  
			|					FROM 
			|						IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedureManagementAccounting
			|		ON IntangibleAssetsAccountingProcedureManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("IABookkeepingProcedureBookkeepingAndTaxAccounting") Then
			
			QueryText = 
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.BUState AS BUState,
			|	RegisterData.StateTa AS StateTa,
			|	RegisterData.VATTaxation AS VATTaxation
			|
			|INTO IABookkeepingProcedureBookkeepingAndTaxAccounting
			|
			|FROM
			|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND (Organization, IntangibleAsset) IN (
			|					SELECT 
			|						IntangibleAssetsRegistrationPlace.Organization,  
			|						IntangibleAssetsRegistrationPlace.IntangibleAsset  
			|					FROM 
			|						IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN IABookkeepingProcedureBookkeepingAndTaxAccounting AS IABookkeepingProcedureBookkeepingAndTaxAccounting
			|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
	
		If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetAmortizationParametersManagementAccounting") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.UsefulLifeMonths AS UsefulLifeMonths,
			|	RegisterData.DepreciationMethod AS DepreciationMethod
			|
			|INTO IntangibleAssetAmortizationParametersManagementAccounting
			|
			|FROM
			|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND (Organization, IntangibleAsset) IN (
			|					SELECT 
			|						IntangibleAssetsRegistrationPlace.Organization,  
			|						IntangibleAssetsRegistrationPlace.IntangibleAsset  
			|					FROM 
			|						IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
			|		ON IntangibleAssetAmortizationParametersManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("IADepreciationParametersBookkeepingAndTaxAccounting") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.Organization AS Organization,
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
			|	RegisterData.UsefulLifeMonthsTA AS UsefulLifeMonthsTA
			|
			|INTO IADepreciationParametersBookkeepingAndTaxAccounting
			|
			|FROM
			|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND (Organization, IntangibleAsset) IN (
			|					SELECT 
			|						IntangibleAssetsRegistrationPlace.Organization,  
			|						IntangibleAssetsRegistrationPlace.IntangibleAsset  
			|					FROM 
			|						IntangibleAssetsRegistrationPlace AS IntangibleAssetsRegistrationPlace)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset,
			|	Organization
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
			|		ON IADepreciationParametersBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
		
		If DescriptionOfSelectionRequest.RequiredTables.Property("IntangibleAssetsAccountingProcedure") Then
			
			QueryText =
			"SELECT ALLOWED
			|	RegisterData.IntangibleAsset AS IntangibleAsset,
			|	RegisterData.FinancialAccountingGroup AS FinancialAccountingGroup,
			|	RegisterData.LineOfBusiness AS LineOfBusiness
			|
			|INTO IntangibleAssetsAccountingProcedure
			|
			|FROM
			|	InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
			|			&DateOfLastEdit,
			|			&Parameters_SliceOfLAST_CONDITIONS
			|				AND IntangibleAsset IN (
			|					SELECT 
			|						TTListOfIa.Ref  
			|					FROM 
			|						TTListOfIa AS TTListOfIa)) AS RegisterData
			|
			|INDEX BY
			|	IntangibleAsset
			|";
			ListOfRequests.Add(QueryText);

			JoinText = JoinText + "
			|		LEFT JOIN IntangibleAssetsAccountingProcedure AS IntangibleAssetsAccountingProcedure
			|		ON IntangibleAssetsAccountingProcedure.Organization = IntangibleAssetsRegistrationPlace.Organization
			|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset
			|"; // @query-part-1
			
		EndIf;
			
		QueryText =
		"SELECT ALLOWED TOP 10
		|	CatalogDataOverridable.Ref AS Ref,
		|	CatalogDataOverridable.Description AS Description
		|
		|FROM
		|	TTListOfIa AS CatalogDataOverridable
		|";
		
		If ValueIsFilled(JoinText) Then
			QueryText = QueryText + Chars.LF + JoinText;
		EndIf;

		ListOfRequests.Add(QueryText);
		
		QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
		
		TextSelections = "";

	Else
		
		QueryText =		
		"SELECT ALLOWED TOP 10
		|	CatalogDataOverridable.Ref AS Ref,
		|	CatalogDataOverridable.Description AS Description
		|
		|FROM	
		|	Catalog.IntangibleAssets AS CatalogDataOverridable
		|";
		
		TextSelections = 
		"WHERE
		|	CatalogDataOverridable.Description LIKE &SearchSubstring
		|	AND NOT CatalogDataOverridable.IsFolder
		|	AND NOT CatalogDataOverridable.DeletionMark
		|";
		
	EndIf;

	If Not IsBlankString(DescriptionOfSelectionRequest.TextSelections) Then
		TextAnd = "AND"; // @query-part-1
		WhereText = "WHERE"; // @query-part-1
		TextSelections = TextSelections
			+ ?(TextSelections <> "", Chars.LF + TextAnd, WhereText) + Chars.LF + DescriptionOfSelectionRequest.TextSelections; 
	EndIf;
	
	If Not IsBlankString(TextSelections) Then
		QueryText = QueryText + Chars.LF + TextSelections;
	EndIf;
	
	QueryText = QueryText + 
	"
	|ORDER BY
	|	Description
	|";
	
	SliceParametersOfLast_Period = "";
	ParametersOfSliceOfLast_Conditions = "TRUE";
	SliceParameters_Registration = "TRUE";
	
	If ChoiceParameters.Property("DateOfLastEdit") Then
		SliceParametersOfLast_Period = "&DateOfLastEdit";
	EndIf; 
	
	If ChoiceParameters.Property("CurrentRegistrar") Then
		ParametersOfSliceOfLast_Conditions = "Recorder <> &CurrentRegistrar";
	EndIf; 
	
	QueryText = StrReplace(QueryText, "&PARAMETERS_AFTERLAST_Period", SliceParametersOfLast_Period);
	QueryText = StrReplace(QueryText, "&Parameters_SliceOfLAST_CONDITIONS", ParametersOfSliceOfLast_Conditions);
	QueryText = StrReplace(QueryText, "&PARAMETERS_LAST_REFERENCES", SliceParameters_Registration);
		
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("SearchSubstring", "%" + Parameters.SearchString + "%");
	Query.SetParameter("DateOfLastEdit", ?(ChoiceParameters.Property("DateOfLastEdit"), EndOfDay(ChoiceParameters.DateOfLastEdit), '00010101'));
	
	For Each ParameterDetails In DescriptionOfSelectionRequest.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;

	If ChoiceParameters.Property("CurrentRegistrar") Then
		Query.SetParameter("CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
	EndIf; 
	
	If ChoiceParameters.Filter.Property("State") Then
		
		FilterValue = NonCurrentAssetsInternal.ValueToArray(ChoiceParameters.Filter.State);
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", Not ValueIsFilled(FilterValue));
		
	Else			
		
		FilterValue = New Array;
		FilterValue.Add(Enums.FixedAssetsStates.EmptyRef());
		
		Query.SetParameter("State", FilterValue);
		Query.SetParameter("DoNotUseStateSelection", True);
		
	EndIf;

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		Presentation = TrimAll(Selection.Description);
		
		Presentation = TMCommonUse.PresentationOfSearchResultsByString(Presentation, Parameters.SearchString);
		ChoiceData.Add(Selection.Ref, Presentation);
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction

Function ThereIsNoFixedAndIntangibleAssetsAccounting2_4(Period) Export
	
	Return GetFunctionalOption("UseNonCurrentAssets2_4")
		And Period < NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
		
EndFunction

// Parameters of the method for reflecting expenses.
// 
// Parameters:
//  ExpensesPostingMethod - CatalogRef.WaysToReflectExpenses - The way expenses are reflected
// 
// Returns:
//  Structure - Parameters Of The Expense Reflection Method:
// 		* ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - AssetRef
// 		* DimensionOfExpenses - AnyRef, Undefined -
// 		* Department - CatalogRef.BusinessStructure -
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness -
// 		* BusinessUnitAndLineOfBusinessMatchAccountingData - Boolean
// 
Function ParametersOfExpenseReflectionMethod(ExpensesPostingMethod) Export
	
	Result = New Structure;
	Result.Insert("ExpenseItem", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	Result.Insert("DimensionOfExpenses", Undefined);
	Result.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	Result.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	Result.Insert("BusinessUnitAndLineOfBusinessMatchAccountingData", True);
	
	AttributesValues = Common.ObjectAttributesValues(ExpensesPostingMethod, "ExpenseItem,DimensionOfExpenses,Department,LineOfBusiness,BusinessUnitAndLineOfBusinessMatchAccountingData");
	
	FillPropertyValues(Result, AttributesValues);
	
	Return Result;
	
EndFunction

// 
// Parameters:
//  Details - Number - Details
//  DetailsDataAddress - String - Address of the decryption data
// 
// Returns:
//  Structure - decryption data:
// 		* Fields - Array - 
Function DetailsData(Details, DetailsDataAddress) Export
	
	Result = New Structure;
	Result.Insert("Fields", New Array);
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); // DataCompositionDetailsData
	
	DetailsItem = DetailsData.Items[Details];
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		
		FieldValues = DetailsItem.GetFields();
		For Each Field In FieldValues Do
			Result.Fields.Add(Field.Field);
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

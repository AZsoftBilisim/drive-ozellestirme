#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	ReconciliationResults.Clear();
	RefillResults = (ExternalSystemData.Count() > 0);
	
	InitializeDocument();
	
	ReconcileOpeningBalancesByWarehousesLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
		
	ReconcileOpeningBalancesByWarehousesLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		ThisObject.GetNewObjectRef();
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		Documents.ReconcileOpeningBalancesByWarehouses.FillInProductTrackingForm(ThisObject);
		Documents.ReconcileOpeningBalancesByWarehouses.FillStockTypes(ThisObject);
		Documents.ReconcileOpeningBalancesByWarehouses.FillInStatusesForSpecifyingSeries(ThisObject);
		
	EndIf;
	
	ReconcileOpeningBalancesByWarehousesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReconcileOpeningBalancesByWarehousesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// Characteristics
	ParametersForCheckingCharacteristics = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	ParametersForCheckingCharacteristics.TSName = "ExternalSystemData";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		ParametersForCheckingCharacteristics);
		
	NotCheckedAttributeArray.Add("ReconciliationResults.Characteristic"); // the reference field cannot be changed manually
	
	// SetOfSeries
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReconcileOpeningBalancesByWarehouses);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		SeriesSpecificationParameters,
		Cancel,
		NotCheckedAttributeArray);
	
	// GTD numbers
	NotCheckedAttributeArray.Add("ReconciliationResults.CCDNumber");
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.TSName = "ReconciliationResults";
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckingCorrectnessOfDocumentDetails(Cancel);
	
	ReconcileOpeningBalancesByWarehousesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReconcileOpeningBalancesByWarehousesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReconcileOpeningBalancesByWarehousesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	AccountingDate = BegOfMonth(Constants.CostAccountingStartDate.Get());
	
	If ValueIsFilled(AccountingDate) Then
		Date = AccountingDate - 1;
	EndIf;
	
EndProcedure

Procedure CheckingCorrectnessOfDocumentDetails(Cancel)
	
	// Let's check the date of the document.
	If Not GetFunctionalOption("UseCostAccounting") Then
		
		Common.MessageToUser(
			NStr("vi = 'Chỉ có thể nhập chứng từ khi bật sử dụng tùy chỉnh ""Sử dụng hạch toán giá vốn""';
				|ru = 'Документ можно вводить только при включенной настройке ""Использовать учет себестоимости""';
				|en = 'The document may be entered only when the setting ""Use the cost accounting"" is on'; fa = 'The document may be entered only when the setting ""Use the cost accounting"" is on';
				|it = 'Il documento può essere inserito solo quando è abilitata l''opzione ""Usa il calcolo dei costi di produzione"".';
				|pl = 'Dokument można uzupełnić tylko wtedy, gdy włączona jest opcja „Użyj ewidencji kosztów własnych”.';
				|tr = 'Belge yalnızca ""Maliyet muhasebesini kullan"" ayarı etkinleştirildiğinde girilebilir'"),
			Ref,
			"Date",
			,
			Cancel);
		
	Else
		
		AccountingDate = BegOfMonth(Constants.CostAccountingStartDate.Get());
		
		If Not ValueIsFilled(AccountingDate) Then
			
			Common.MessageToUser(
				NStr("vi = 'Chỉ có thể nhập chứng từ khi đặt hằng ""Ngày bắt đầu hạch toán giá vốn""';
					|ru = 'Документ можно вводить только при установленной константе ""Дата начала учета себестоимости""';
					|en = 'The document may be entered only when the constant ""Start date of cost accounting"" is set up'; fa = 'The document may be entered only when the constant ""Start date of cost accounting"" is set up';
					|it = 'Il documento può essere inserito solo una volta alla costante impostata ""Data di inizio del calcolo di costi di produzione""';
					|pl = 'Dokument można uzupełnić tylko podczas ustawionej stałej ""Data początku ewidencji wartości własnej""';
					|tr = 'Belge yalnızca ""Maliyet muhasebesinin başlangıç ​​tarihi"" sabiti ayarlanmışsa girilebilir.'"),
				Ref,
				"Date",
				,
				Cancel);
			
		ElsIf EndOfMonth(Date) + 1 <> AccountingDate Then
			
			Common.MessageToUser(
				NStr("vi = 'Chỉ có thể nhập chứng từ vào tháng trước tháng đặt hằng ""Ngày bắt đầu hạch toán giá vốn""';
					|ru = 'Документ можно вводить только в месяце, предшествующем месяцу константы ""Дата начала учета себестоимости""';
					|en = 'The document may be entered only in the month before the month of the constant ""Start date of cost accounting""'; fa = 'The document may be entered only in the month before the month of the constant ""Start date of cost accounting""';
					|it = 'L documento può essere inserito solo nel mese che precede il mese della costante ""Data di inizio della contabilità dei costi di produzione""';
					|pl = 'Dokument można uzupełnić tylko w miesiącu, poprzedzającemu miesiąc stałej ""Data początku ewidencji wartości własnej""';
					|tr = 'Belge yalnızca ""Maliyet muhasebesinin başlangıç ​​tarihi"" sabitinin ayarlandığı aydan önceki aya girilebilir.'"),
				Ref,
				"Date",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// Let's check the document warehouse.
	Query = New Query;
	Query.SetParameter("Ref", 	 Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", 		 Warehouse);
	
	Query.Text =
	"SELECT
	|	T.Ref AS Ref
	|FROM
	|	Document.ReconcileOpeningBalancesByWarehouses AS T
	|WHERE
	|	T.Ref <> &Ref
	|	AND T.Organization = &Organization
	|	AND T.Warehouse = &Warehouse
	|	AND NOT T.DeletionMark";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Common.MessageToUser(
			NStr("vi = 'Đối với doanh nghiệp và kho được chỉ định, có các chứng từ khác để đối chiếu số dư ban đầu của kho';
				|ru = 'По указанным организации и складу существуют другие документы сверки начальных остатков по складу';
				|en = 'Other documents of initial balance consolidation by a warehouse exist by the specified company and the warehouse'; fa = 'Other documents of initial balance consolidation by a warehouse exist by the specified company and the warehouse';
				|it = 'Per aziende e magazzino specificati, esistono altri documenti di riconciliazione dei saldi iniziali del magazzino.';
				|pl = 'Dla wskazanej firmy i magazynu istnieją inne dokumenty uzgadniające początkowe pozostałości wg magazynu';
				|tr = 'Belirtilen iş yeri ve ambar için, ambardaki başlangıç ​​bakiyelerinin mutabakatına yönelik diğer belgeler mevcuttur.'"),
			Ref,
			"Warehouse",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

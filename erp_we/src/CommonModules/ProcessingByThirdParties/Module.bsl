////////////////////////////////////////////////////////////////////////////////
// Subsystem "Processing on the side".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region CostGroups

// The text of the request "Imported products of the document".
// 
// Returns:
//  String - Request Text TT Imported Products Document
Function QueryTextTTImportedProducts() Export
	
	QueryText =
	"SELECT
	|	ProductTable_.CostGroupNumber	AS CostGroupNumber,
	|	ProductTable_.Products			AS Products,
	|	ProductTable_.Characteristic		AS Characteristic,
	|	ProductTable_.Traceable		AS Traceable
	|INTO TTImportedProducts
	|FROM
	|	(SELECT
	|		TabularSection.CostGroupNumber		AS CostGroupNumber,
	|		TabularSection.Products				AS Products,
	|		TabularSection.Characteristic			AS Characteristic,
	|		ISNULL(Goods.KeepRecordsByCCD, FALSE)	AS Imported_,
	|		CASE
	|			WHEN ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|						(VALUE(Enum.ItemsTypes.OwnGoods),
	|						VALUE(Enum.ItemsTypes.ReusablePackage))
	|				THEN CASE
	|						WHEN NOT &UseTraceableImportedGoodsAccounting
	|								OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|							THEN FALSE
	|						ELSE ISNULL(Goods.TracedGoods, FALSE)
	|					END
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				THEN ISNULL(Goods.TracedGoods, FALSE)
	|			ELSE FALSE
	|		END									AS Traceable
	|	FROM
	|		ManufacturedProducts AS TabularSection
	|		
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TabularSection.Products = Goods.Ref
	|	
	|	WHERE
	|		ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|					(VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.Work_5),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.CostGroupNumber		AS CostGroupNumber,
	|		TabularSection.Products				AS Products,
	|		TabularSection.Characteristic			AS Characteristic,
	|		ISNULL(Goods.KeepRecordsByCCD, FALSE)	AS Imported_,
	|		CASE
	|			WHEN ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|						(VALUE(Enum.ItemsTypes.OwnGoods),
	|						VALUE(Enum.ItemsTypes.ReusablePackage))
	|				THEN CASE
	|						WHEN NOT &UseTraceableImportedGoodsAccounting
	|								OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|							THEN FALSE
	|						ELSE ISNULL(Goods.TracedGoods, FALSE)
	|					END
	|			WHEN &UseTraceableImportedGoodsAccounting
	|				THEN ISNULL(Goods.TracedGoods, FALSE)
	|			ELSE FALSE
	|		END									AS Traceable
	|	FROM
	|		SideAndIntermediateRelease AS TabularSection
	|		
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TabularSection.Products = Goods.Ref
	|	
	|	WHERE
	|		ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|				(VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.Work_5),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	) AS ProductTable_
	|
	|WHERE
	|	ProductTable_.Imported_
	|
	|GROUP BY
	|	ProductTable_.CostGroupNumber,
	|	ProductTable_.Products,
	|	ProductTable_.Characteristic,
	|	ProductTable_.Traceable
	|
	|INDEX BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic
	|";
	
	Return QueryText;
	
EndFunction

// The text of the check is not filled in by the cost group of the document.
// 
// Parameters:
//  TSName - String
//  TableNameTSName - String
//  SynonymTSNameTS - String
// 
// Returns:
//  String - The text of the check is not filled in the cost group of the document
Function CheckTextNotFilledInCostGroupTSDocument(TSName, TableNameTSName, SynonymTSNameTS) Export
	
	QueryText =
	"SELECT
	|	&TableNameTSName            AS TableName,
	|	&SynonymTSNameTS             AS TSSynonym,
	|	TabularSection.LineNumber  AS LineNumber,
	|	0                           AS CostGroupNumber,
	|	""CostGroupNotFilledIn"" AS TypeOfVerification
	|FROM
	|	TSName AS TabularSection
	|WHERE
	|	TabularSection.CostGroupNumber = 0
	|";
	
	QueryText = StrReplace(QueryText, "TableNameTSName", TableNameTSName);
	QueryText = StrReplace(QueryText, "SynonymTSNameTS",  SynonymTSNameTS);
	QueryText = StrReplace(QueryText, "TSName",           TSName);
	
	Return QueryText;
	
EndFunction

// The verification text does not match the order.
// 
// Parameters:
//  TSName - String
//  TableNameTSName - String
//  SynonymTSNameTS - String
// 
// Returns:
//  String - The verification text does not match the order
Function VerificationTextDoesNotMatchOrder(TSName, TableNameTSName, SynonymTSNameTS) Export
	
	QueryText =
	"SELECT
	|	&TableNameTSName                 AS TableName,
	|	&SynonymTSNameTS                  AS TSSynonym,
	|	TabularSection.LineNumber       AS LineNumber,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	""DoesNotMatchOrder""        AS TypeOfVerification
	|FROM
	|	TSName AS TabularSection
	|	
	|	LEFT JOIN CostGroupNumbersNotIncludedInOrder AS CostGroupNumbers
	|	ON CostGroupNumbers.CostGroupNumber = TabularSection.CostGroupNumber
	|WHERE
	|	CostGroupNumbers.CostGroupNumber IS NOT NULL
	|";
	
	QueryText = StrReplace(QueryText, "TableNameTSName", TableNameTSName);
	QueryText = StrReplace(QueryText, "SynonymTSNameTS",  SynonymTSNameTS);
	QueryText = StrReplace(QueryText, "TSName",           TSName);
	
	Return QueryText;
	
EndFunction

// The text of the check is a non-existent cost group of the document.
// 
// Parameters:
//  TSName - String
//  TableNameTSName - String
//  SynonymTSNameTS - String
// 
// Returns:
//  String - The text of the check is a non-existent cost group of the document
Function VerificationTextNonExistentCostGroupTSDocument(TSName, TableNameTSName, SynonymTSNameTS) Export
	
	QueryText =
	"SELECT
	|	&TableNameTSName                 AS TableName,
	|	&SynonymTSNameTS                  AS TSSynonym,
	|	TabularSection.LineNumber       AS LineNumber,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	""SpecifiedNonExistent""        AS TypeOfVerification
	|FROM
	|	TSName AS TabularSection
	|	
	|	LEFT JOIN CostGroupNumbers AS CostGroupNumbers
	|	ON CostGroupNumbers.CostGroupNumber = TabularSection.CostGroupNumber
	|WHERE
	|	NOT TabularSection.CostGroupNumber = 0
	|	AND CostGroupNumbers.CostGroupNumber IS NULL
	|";
	
	QueryText = StrReplace(QueryText, "TableNameTSName", TableNameTSName);
	QueryText = StrReplace(QueryText, "SynonymTSNameTS",  SynonymTSNameTS);
	QueryText = StrReplace(QueryText, "TSName",           TSName);
	
	Return QueryText;
	
EndFunction

// The text of the check does not specify the destination.
// 
// Parameters:
//  Filter - Map - selection description
// 
// Returns:
//  String - Verification Text No Destination Specified
//
Function VerificationTextNoDestinationSpecified(Filter = Undefined) Export
	
	QueryText = 
	"SELECT
	|	&TableNameOutputProducts       AS TableName,
	|	&SynonymForTSOutputProducts        AS TSSynonym,
	|	TabularSection.LineNumber       AS LineNumber,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	""NoDestinationSpecified""          AS TypeOfVerification
	|FROM
	|	ManufacturedProducts AS TabularSection
	|WHERE
	|	&GroupCosts IN(
	|		VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments),
	|		VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|	AND TabularSection.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND NOT TabularSection.ToExpenseAs
	|	AND &AddtlFilter
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&AddtlFilter", FilterText1);
	
	Return QueryText;
	
EndFunction

// The text of the check does not specify the products.
// 
// Parameters:
//  Filter - Map - selection description
// 
// Returns:
//  String - The Text Of The Check Does Not Specify The Products
Function TextOfCheckDoesNotSpecifyProducts(Filter = Undefined) Export
	
	QueryText = 
	"SELECT
	|	&TableNameOutputProducts          AS TableName,
	|	&SynonymForTSOutputProducts           AS TSSynonym,
	|	0                                   AS LineNumber,
	|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber,
	|	""ProductsNotSpecified""                AS TypeOfVerification
	|FROM
	|	CostGroupNumbers AS CostGroupNumbers
	|	
	|	LEFT JOIN ManufacturedProducts AS TabularSection
	|	ON TabularSection.CostGroupNumber = CostGroupNumbers.CostGroupNumber
	|WHERE
	|	&GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	AND TabularSection.CostGroupNumber IS NULL
	|	AND CAST(CostGroupNumbers.ProductionStage AS Document.ProductionStage2_2).NextStageNo = 0
	|	AND &AddtlFilter
	|
	|UNION ALL
	|
	|SELECT
	|	&NameOfByProductTable          AS TableName,
	|	&SynonymOfTSByProducts           AS TSSynonym,
	|	0                                   AS LineNumber,
	|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber,
	|	""ProductsNotSpecified""                AS TypeOfVerification
	|FROM
	|	CostGroupNumbers AS CostGroupNumbers
	|	
	|	LEFT JOIN SideAndIntermediateRelease AS TabularSection
	|	ON TabularSection.CostGroupNumber = CostGroupNumbers.CostGroupNumber
	|WHERE
	|	&GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	AND TabularSection.CostGroupNumber IS NULL
	|	AND NOT CAST(CostGroupNumbers.ProductionStage AS Document.ProductionStage2_2).NextStageNo = 0
	|	AND &AddtlFilter
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&AddtlFilter", FilterText1);
	
	Return QueryText;
	
EndFunction

// The verification text does not specify the materials.
// 
// Parameters:
//  TSName - String
//  TableNameTSName - String
//  SynonymTSNameTS - String
//  Filter - Map - selection description
// 
// Returns:
//  String - Verification text materials are not specified
Function VerificationTextMaterialsNotSpecified(TSName, TableNameTSName, SynonymTSNameTS, Filter = Undefined) Export
	
	QueryText = 
	"SELECT
	|	&TableNameTSName                    AS TableName,
	|	&SynonymTSNameTS                     AS TSSynonym,
	|	TabularSection.LineNumber          AS LineNumber,
	|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber,
	|	""MaterialsNotSpecified""              AS TypeOfVerification
	|FROM
	|	CostGroupNumbers AS CostGroupNumbers
	|	
	|	LEFT JOIN TSName AS TabularSection
	|	ON TabularSection.CostGroupNumber = CostGroupNumbers.CostGroupNumber
	|WHERE
	|	TabularSection.CostGroupNumber IS NULL
	|	AND &AddtlFilter
	|";
	
	QueryText = StrReplace(QueryText, "TableNameTSName", TableNameTSName);
	QueryText = StrReplace(QueryText, "SynonymTSNameTS",  SynonymTSNameTS);
	QueryText = StrReplace(QueryText, "TSName",           TSName);
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&AddtlFilter", FilterText1);
	
	Return QueryText;
	
EndFunction

// The verification text does not specify services.
// 
// Parameters:
//  Filter - Undefined - Filter
// 
// Returns:
//  String - Verification Text Services Not Specified
Function VerificationTextServicesNotSpecified(Filter = Undefined) Export
	
	QueryText = 
	"SELECT
	|	&ServiceTableName                   AS TableName,
	|	&SynonymForTSServices                    AS TSSynonym,
	|	TabularSection.LineNumber          AS LineNumber,
	|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber,
	|	""ServicesNotSpecified""                 AS TypeOfVerification
	|FROM
	|	CostGroupNumbers AS CostGroupNumbers
	|	
	|	LEFT JOIN Services AS TabularSection
	|	ON TabularSection.CostGroupNumber = CostGroupNumbers.CostGroupNumber
	|WHERE
	|	TabularSection.CostGroupNumber IS NULL
	|	AND &ProcessingServices = VALUE(Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder)
	|	AND &AddtlFilter
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&AddtlFilter", FilterText1);
	
	Return QueryText;
	
EndFunction

// The text of the check is "Several imported products".
// 
// Returns:
//  String - Text Check Multiple Imported Products
Function TextCheckMultipleImportedProducts() Export
	
	QueryText =
	"SELECT
	|	&NameOfManufacturedProductsPage               AS TableName,
	|	""""                                AS TSSynonym,
	|	0                                   AS LineNumber,
	|	CostGroupNumbers.CostGroupNumber AS CostGroupNumber,
	|	""SeveralImportedProducts""       AS TypeOfVerification
	|FROM
	|	CostGroupNumbers AS CostGroupNumbers
	|	
	|	LEFT JOIN TTImportedProducts AS ImportedProductsOfDocument
	|	ON ImportedProductsOfDocument.CostGroupNumber = CostGroupNumbers.CostGroupNumber
	|
	|WHERE
	|	&UseImportedGoods
	|
	|GROUP BY
	|	CostGroupNumbers.CostGroupNumber
	|
	|HAVING
	|	COUNT(ImportedProductsOfDocument.CostGroupNumber) > 1
	|";
	
	Return QueryText;
	
EndFunction

Procedure ReportErrorsFillingCostGroups(Selection, PresentationOfCostGroups, Cancel) Export
	
	TemplateDoesNotMatchOrder     = NStr("vi = 'Tại dòng ""%1"" của danh sách ""%2"" đã chỉ ra nhóm chi phí không có trong đơn hàng gia công.';
										|ru = 'В строке ""%1"" списка ""%2"" указана группа затрат, отсутствующая в заказе переработчику.';
										|en = 'The ""%1"" line of the ""%2"" list contains the cost group missing in ""Subcontracting purchase order"".'; fa = 'The ""%1"" line of the ""%2"" list contains the cost group missing in ""Subcontracting purchase order"".';
										|it = 'Nella riga ""%1"" dell''elenco ""%2"" è indicato il gruppo di spesa mancante nell''ordine all''elaboratore.';
										|pl = 'W wierszu ""%1"" listy ""%2"" jest podana grupa kosztów, której nie ma w zamówieniu przetwórcy.';
										|tr = '""%2"" listesinin ""%1"" satırında, verilen fason üretici siparişinde bulunmayan maliyet grubu belirtildi.'");
	TemplateNotFilledInGroup         = NStr("vi = 'Chưa điền nhóm chi phí tại dòng ""%1"" của danh sách ""%2"".';
											|ru = 'Не заполнена группа затрат в строке ""%1"" списка ""%2"".';
											|en = 'Cost group in the ""%1"" line of the ""%2"" list is not filled in.'; fa = 'Cost group in the ""%1"" line of the ""%2"" list is not filled in.';
											|it = 'Il gruppo di spesa nella riga ""%1"" dell''elenco ""%2"" non è compilato.';
											|pl = 'Grupa kosztów nie jest wypełniona w wierszu ""%1"" listy ""%2"".';
											|tr = '""%2"" listesinin ""%1"" satırındaki maliyet grubu doldurulmadı.'");
	TemplateSpecifiedNonexistent     = NStr("vi = 'Tại dòng ""%1"" của danh sách ""%2"" đã chỉ ra nhóm chi phí mà không có xuất xưởng sản phẩm.';
											|ru = 'В строке ""%1"" списка ""%2"" указана группа затрат, по которой отсутствует выпуск изделий.';
											|en = 'The ""%1"" line of the ""%2"" list contains the cost group for which there is no finished product release.'; fa = 'The ""%1"" line of the ""%2"" list contains the cost group for which there is no finished product release.';
											|it = 'Nella riga ""%1"" dell''elenco ""%2"" è indicato un gruppo di spesa per il quale manca la produzione.';
											|pl = 'W wierszu ""%1"" listy ""%2"" podana jest grupa kosztów, według której nie ma wyprodukowania wyrobów.';
											|tr = '""%2"" listesinin ""%1"" satırında, nihai ürün çıkışı bulunmayan maliyet grubu belirtildi.'");
	TemplateNotSpecifiedProducts          = NStr("vi = 'Đối với nhóm chi phí ""%1"" chưa chỉ ra xuất xưởng sản phẩm.';
												|ru = 'Для группы затрат ""%1"" не указан выпуск изделий.';
												|en = 'Finished product release is not specified for the ""%1"" cost group.'; fa = 'Finished product release is not specified for the ""%1"" cost group.';
												|it = 'Per il gruppo di spesa ""%1"" non è indicata la produzione.';
												|pl = 'Dla grupy kosztów ""%1"" nie jest podane wyprodukowanie wyrobów.';
												|tr = '""%1"" maliyet grubu için nihai ürün çıkışı belirtilmedi.'");
	TemplateWrongValueType  = NStr("vi = 'Không thể xuất xưởng sản phẩm theo giá vốn đã tính, bởi vì công doạn liên quan đến sản phẩm không phải là xuất xưởng.';
									|ru = 'Выпуск изделий по рассчитываемой стоимости недоступен, т.к. этап, к которому относится изделие, не является выпускающим.';
									|en = 'Finished product release at the calculated cost is unavailable as the stage of the product is not a release one.'; fa = 'Finished product release at the calculated cost is unavailable as the stage of the product is not a release one.';
									|it = 'La produzione al costo calcolato non è disponibile, perché la fase alla quale appartiene il prodotto non è quella di emissione.';
									|pl = 'Wyprodukowanie wyrobów według obliczonej wartości nie jest dostępne, ponieważ etap, do którego należą wyroby, nie jest produkcyjnym.';
									|tr = 'Nihai ürünün ait olduğu aşama ürün çıkışına yönelik olmadığı için hesaplanan maliyetle nihai ürün çıkışı mümkün değildir.'");
	TemplateNoDestinationSpecified       = NStr("vi = 'Cần chỉ ra mục đích tại dòng ""%1"" trong danh sách ""%2""';
												|ru = 'Необходимо указать назначение в строке ""%1"" списка ""%2""';
												|en = 'Specify the assignment in the ""%1"" line of the ""%2"" list'; fa = 'Specify the assignment in the ""%1"" line of the ""%2"" list';
												|it = 'È necessario indicare l''assegnazione nella riga ""%1"" dell''elenco ""%2""';
												|pl = 'Należy podać przeznaczenie w wierszu ""%1"" listy ""%2""';
												|tr = '""%2"" listesinin ""%1"" satırında atama belirtmeniz gerekmektedir.'");
	TemplateNotSpecifiedMaterials        = NStr("vi = 'Đối với nhóm chi phí ""%1"" chưa chỉ ra nguyên vật liệu và công việc.';
												|ru = 'Для группы затрат ""%1"" не указаны материалы и работы.';
												|en = 'Materials and works are not specified for the ""%1"" cost group.'; fa = 'Materials and works are not specified for the ""%1"" cost group.';
												|it = 'Per il gruppo di spesa ""%1"" non sono indicati materiali e lavori.';
												|pl = 'Dla grupy kosztów ""%1"" nie są podane materiały i prace.';
												|tr = '""%1"" maliyet grubu için malzemeler ve işler belirtilmedi.'");
	TemplateNotSpecifiedServices           = NStr("vi = 'Đối với nhóm chi phí ""%1"" chưa chỉ ra dịch vụ của bên nhận gia công.';
													|ru = 'Для группы затрат ""%1"" не указаны услуги переработчика.';
													|en = 'Subcontractor services are not specified for the ""%1"" cost group.'; fa = 'Subcontractor services are not specified for the ""%1"" cost group.';
													|it = 'Per il gruppo di spesa ""%1"" non sono indicati i servizi dell''elaboratore.';
													|pl = 'Dla grupy kosztów ""%1"" nie są podane usługi przetwórcy.';
													|tr = '""%1"" maliyet grubu için fason üretici hizmetleri belirtilmedi.'");
	TemplateMultipleImportedProducts = NStr("vi = 'Đối với nhóm chi phí ""%1"" đã chỉ ra nhiều sản phẩm nhập khẩu.';
											|ru = 'Для группы затрат ""%1"" указано несколько импортных изделий.';
											|en = 'Several imported finished products are specified for the ""%1"" cost group.'; fa = 'Several imported finished products are specified for the ""%1"" cost group.';
											|it = 'Per il gruppo di spesa ""%1"" sono indicate alcune produzioni di importazione.';
											|pl = 'Dla grupy kosztów ""%1"" podano kilka wyrobów importowych.';
											|tr = '""%1"" maliyet grubu için birden fazla ithal ürün belirtildi.'");
	TemplateNotSpecifiedImportedMaterial = NStr("vi = 'Đối với nhóm chi phí ""%1"" chưa chỉ ra nguyên liệu nhập khẩu hoặc công việc.';
												|ru = 'Для группы затрат ""%1"" не указан импортный материал или работа.';
												|en = 'No imported material or work is specified for the ""%1"" cost group.'; fa = 'No imported material or work is specified for the ""%1"" cost group.';
												|it = 'No imported material or work is specified for the ""%1"" cost group.';
												|pl = 'No imported material or work is specified for the ""%1"" cost group.';
												|tr = '""%1"" maliyet grubu için ithal malzeme ya da iş belirtilmedi.'");
	
	While Selection.Next() Do
		
		LineNumber = Format(Selection.LineNumber, "NG=");
		
		If Selection.TypeOfVerification = "DoesNotMatchOrder" Then
			
			MessageText = StrTemplate(TemplateDoesNotMatchOrder, LineNumber, Selection.TSSynonym);
			Field = CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "ExpenseGroup");
			Common.MessageToUser(
				MessageText,,
				Field,
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "CostGroupNotFilledIn" Then
			
			MessageText = StrTemplate(TemplateNotFilledInGroup, LineNumber, Selection.TSSynonym);
			Field = CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "ExpenseGroup");
			Common.MessageToUser(
				MessageText,,
				Field,
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "SpecifiedNonExistent" Then
			
			MessageText = StrTemplate(TemplateSpecifiedNonexistent, LineNumber, Selection.TSSynonym);
			Field = CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "ExpenseGroup");
			Common.MessageToUser(
				MessageText,,
				Field,
				"Object");
			
		EndIf;
		
		If Selection.TypeOfVerification = "NoDestinationSpecified" Then
			
			MessageText = StrTemplate(TemplateNoDestinationSpecified, LineNumber, Selection.TSSynonym);
			Field = CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "Purpose");
			Common.MessageToUser(
				MessageText,,
				Field,
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "MaterialsNotSpecified" Then
			
			MessageText = StrTemplate(TemplateNotSpecifiedMaterials, PresentationOfCostGroups[Selection.CostGroupNumber]);
			Common.MessageToUser(
				MessageText,,
				Selection.TableName,
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "ServicesNotSpecified" Then
			
			MessageText = StrTemplate(TemplateNotSpecifiedServices, PresentationOfCostGroups[Selection.CostGroupNumber]);
			Common.MessageToUser(
				MessageText,,
				Selection.TableName,
				"Object");
			
		EndIf;
		If Selection.TypeOfVerification = "ProductsNotSpecified" Then
			
			MessageText = StrTemplate(TemplateNotSpecifiedProducts, PresentationOfCostGroups[Selection.CostGroupNumber]);
			Common.MessageToUser(
				MessageText,,
				Selection.TableName,
				"Object");
			
		EndIf;
		
		If Selection.TypeOfVerification = "IncorrectCostType" Then
			
			MessageText = StrTemplate(TemplateWrongValueType, LineNumber, Selection.TSSynonym);
			Field = CommonClientServer.PathToTabularSection(Selection.TableName, Selection.LineNumber, "ExpenseGroup");
			Common.MessageToUser(
				MessageText,,
				Field,
				"Object",
				Cancel);
			
		EndIf;
		If Selection.TypeOfVerification = "SeveralImportedProducts" Then
			
			MessageText =
				StrTemplate(TemplateMultipleImportedProducts, PresentationOfCostGroups[Selection.CostGroupNumber]);
			
			Common.MessageToUser(
				MessageText,,
				Selection.TableName,
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "ImportedMaterialNotSpecified" Then
			
			MessageText =
				StrTemplate(TemplateNotSpecifiedImportedMaterial, PresentationOfCostGroups[Selection.CostGroupNumber]);
			
			Common.MessageToUser(
				MessageText,,
				Selection.TableName,
				"Object",
				Cancel);
			
		EndIf;
		
		ProcessingByThirdPartiesLocalization.ReportErrorsFillingCostGroups(Selection, PresentationOfCostGroups, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region HandlersForMonthClosingStages

#Region CorrectErrorsInInitialData

Procedure CheckingForSecondaryReleaseWithoutMainOneInProcessorSReport25(CheckParameters) Export
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Organization AS Organization
	|
	|INTO SideIssueWithoutMainOneInReportOfProcessor25
	|FROM 
	|	Document.SubcontractorReport2_5 AS DocumentData
	|	INNER JOIN Document.SubcontractorReport2_5.SideAndIntermediateRelease AS SubcontractorReport2_5SideAndIntermediateRelease
	|	ON DocumentData.Ref = SubcontractorReport2_5SideAndIntermediateRelease.Ref
	|		AND DocumentData.Posted
	|		AND DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentData.Organization IN (&CompanyArray)
	|	
	|	LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS SubcontractorReport2_5ManufacturedProducts
	|	ON (SubcontractorReport2_5SideAndIntermediateRelease.Ref = SubcontractorReport2_5ManufacturedProducts.Ref)
	|
	|	LEFT JOIN Document.SubcontractOrder2_5.References AS DocumentIsSubcontractPurchaseOrderToProcessorOfOrder
	|	ON DocumentData.SubcontractOrder = DocumentIsSubcontractPurchaseOrderToProcessorOfOrder.Ref
	|
	// The order may be a stage, or it may be an order for production.
	// If it is a stage, then the check should be triggered only if it is a releasing stage.
	|	LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
	|	ON ProductionStage2_2.Ref = DocumentIsSubcontractPurchaseOrderToProcessorOfOrder.ReferenceOrder
	|
	|WHERE
	|	SubcontractorReport2_5ManufacturedProducts.Ref IS NULL
	|	AND ISNULL(ProductionStage2_2.NextStageNo, 0) = 0
	|";
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Организация';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Recorder", NStr("vi = 'Chứng từ';
									|ru = 'Документ';
									|en = 'Document'; fa = 'سند';
									|it = 'Документ';
									|pl = 'Dokument';
									|tr = 'Belge'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"SideIssueWithoutMainOneInReportOfProcessor25",
		NStr("vi = 'Đã tìm thấy bảng kê hàng hóa của bên nhận gia công có xuất xưởng theo giá trị cố định mà không có xuất xưởn theo giá trị tính toán trong doanh nghiệp ""%1"" trong kỳ %2';
			|ru = 'Обнаружены отчеты переработчика с выпуском по фиксированной стоимости без выпуска по расчетной в организации ""%1"" за период %2';
			|en = 'Subcontracting services notifications received with release at the fixed cost without release at the estimated cost in the ""%1"" company for the %2 period are found'; fa = 'Subcontracting services notifications received with release at the fixed cost without release at the estimated cost in the ""%1"" company for the %2 period are found';
			|it = 'Обнаружены отчеты переработчика с выпуском по фиксированной стоимости без выпуска по расчетной в организации ""%1"" за период %2';
			|pl = 'Subcontracting services notifications received with release at the fixed cost without release at the estimated cost in the ""%1"" company for the %2 period are found';
			|tr = '""%1"" iş yerinde %2 dönemi için tahmini maliyetle ürün çıkışı olmayan sabit maliyetle ürün çıkışı olan fason üretici raporları bulundu'", Common.DefaultLanguageCode()),
		FieldList,
		"Recorder");
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters,
		QueryText,,
		Enums.AccountingIssueSeverity.Warning);
	
EndProcedure


#EndRegion

#Region CheckingBalancesForProcessingProcessorsReports

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_RequirementsForProcessingProcessorsReports(StepsTable,CurrentParent) Export
	
	NewRow =  MonthEndTransactionsServer.AddStageToTable(
		StepsTable,
		CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterSubcontractorReports);
	
	
	NewRow.MultilingualName = "vi = 'Lập bảng kê hàng hóa của bên nhận gia công';
								|ru = 'Оформление отчетов переработчиков';
								|en = 'Register subcontractor reports';
								|it = 'Registrazione report elaboratori';
								|pl = 'Utworzenie raportów przetwórców';
								|tr = 'Fason üretici hizmetleri bildirimlerinin düzenlenmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProcessingByThirdParties.Processing_RequirementsForProcessingProcessorsReports");
	NewRow.ActionUse =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProcessingByThirdParties.Usage_RequirementsForProcessingProcessorsReports");
	
	NewRow.ActionExecute  =  MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.DocumentsOfTransferToTollingAll2_5.Forms.ToRegisterInvoices.FullName(), True);
	NewRow.ActionExecute.FormParameters.Insert("CurrentPageName", "ReportsPage");
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Usage_RequirementsForProcessingProcessorsReports(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	StockBalance.Organization                AS Organization,
	|	StockBalance.ItemsLocationAttributes AS Dimension,
	|	-StockBalance.CountBalance         AS Balance
	|INTO RequirementsForProcessingProcessorsReports
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)) AS StockBalance
	|
	|WHERE
	|	StockBalance.CountBalance < 0
	|	AND StockBalance.InventoryOwnerAttribute.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.SubcontractorProducts),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|	AND (ISNULL(StockBalance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|		VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|		OR ISNULL(StockBalance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|		VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|";
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.RequirementsForProcessingProcessorsReports = 0 Then

		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư cần lập bảng kê của bên nhận gia công.';
				|ru = 'Нет остатков к оформлению отчетов переработчиков.';
				|en = 'There is no balance to register ""Subcontracting services notifications received"".'; fa = 'There is no balance to register ""Subcontracting services notifications received"".';
				|it = 'Non vi sono saldi da registrare dei report elaboratori.';
				|pl = 'Brak zapasów do generowania raportów przetwórców.';
				|tr = 'Fason üretici raporunun düzenlenecek bakiyesi yok.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// Forms out the closing stage of the month.
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Processing_RequirementsForProcessingProcessorsReports(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Lập chứng từ';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Preparare';
													|pl = 'Register';
													|tr = 'Düzenle'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure DescriptionOfInspections_RequirementsForProcessingProcessorsReports(TableOfChecks) Export
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(
		TableOfChecks,
		"RegisterSubcontractorReports",
		Catalogs.MonthEndClosingOperations.RegisterSubcontractorReports,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"ProcessingByThirdParties.VerificationOfRequirementsForProcessingProcessorsReports");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa lập bảng kê của người nhận gia công.';
			|ru = 'Не оформлены отчеты переработчиков.';
			|en = '""Subcontracting services notifications received"" are not registered.'; fa = '""Subcontracting services notifications received"" are not registered.';
			|it = 'Non sono registrati i report elaboratori.';
			|pl = 'Nie utworzono raportów przetwórców.';
			|tr = 'Fason üretici hizmetleri bildirimleri düzenlenmedi.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần lập bảng kê đối với tất cả hàng hóa đã tiếp nhận từ người nhận gia công.';
			|ru = 'На все поступившие от переработчика изделия должны быть оформлены отчеты переработчика.';
			|en = '""Subcontracting services notification received"" must be registered for all products received from the subcontractor.'; fa = '""Subcontracting services notification received"" must be registered for all products received from the subcontractor.';
			|it = 'Per tutte le produzioni in ricezione dall''elaboratore devono essere registrati i report dell''elaboratore.';
			|pl = 'Na wszystkie wyroby, które wpłynęły od przetwórcy, powinny być utworzone raporty przetwórcy.';
			|tr = 'Fason üreticiden alınan tüm nihai ürünlere yönelik alınan fason hizmetleri bildirimi düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

// Error logging.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfRequirementsForProcessingProcessorsReports(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Dimension",   NStr("vi = 'Đối tượng phân tích';
										|ru = 'Аналитика';
										|en = 'Dimension'; fa = 'بُعد';
										|it = 'Analitica';
										|pl = 'Dimension';
										|tr = 'Boyut'",   Common.DefaultLanguageCode()));
	FieldList.Add("Balance",     NStr("vi = 'Số dư';
										|ru = 'Остаток';
										|en = 'Balance'; fa = 'مانده';
										|it = 'Rimanenze';
										|pl = 'Balance';
										|tr = 'Bakiye'",     Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"RequirementsForProcessingProcessorsReports",
		NStr("vi = 'Đã phát hiện số dư cần lập bảng kê của người nhận gia công theo doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены остатки к оформлению отчетов переработчиков по организации ""%1"" на конец периода %2';
			|en = 'Balance to register ""Subcontracting services notifications received"" for the ""%1"" company at the end of the %2 period are found'; fa = 'Balance to register ""Subcontracting services notifications received"" for the ""%1"" company at the end of the %2 period are found';
			|it = 'Sono stati rilevati saldi in registrazione dei report degli elaboratori per l''azienda ""%1"" alla fine del periodo %2';
			|pl = 'Wykryto zapasy do sporządzenia raportów przetwórców według firmy ""%1"" na koniec okresu %2';
			|tr = '%2 dönemi sonunda ""%1"" iş yerine göre düzenlenecek alınan fason üretici hizmetleri bildirimi bakiyeleri tespit edildi'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),	
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of the processing on the side.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
// 
// Parameters:
//  ThisIsProductionOfEEU - Boolean - a sign of the processor's production in the EAEU countries.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction(ThisIsProductionOfEEU = False) Export
	
	If ThisIsProductionOfEEU Then 
		Return Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5;
	Else
		Return Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with suppliers
//
// Returns:
//  Boolean - 
//
Function AgreementsWithSuppliersAreApplicable() Export
	
	Return False;
	
EndFunction

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return False;
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return False;

EndFunction

#EndRegion

#Region Form

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;

	PurchasesServer.SetContractAvailability(
		Object, Items.Contract.Enabled, Items.Contract.Visible, Contract);
	
EndProcedure

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object) Export
	
	ObjectParameters = New Structure;
	ObjectParameters.Insert("Partner",     Object.Partner);
	ObjectParameters.Insert("Contract",     Object.Contract);
	ObjectParameters.Insert("Counterparty",  Object.Counterparty);
	ObjectParameters.Insert("Organization", Object.Organization);
	ObjectParameters.Insert("Terms",  Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	
	Return PurchasesServer.GetDefaultContract(ObjectParameters, ContractBusinessTransaction());
	
EndFunction

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
			
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo người nhận gia công';
																		|ru = 'По переработчику';
																		|en = 'By subcontractor'; fa = 'By subcontractor';
																		|it = 'Per elaboratore';
																		|pl = 'Wg przetwórcy';
																		|tr = 'Fason üreticiye göre'")));
			
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray       = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
			
	ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	If GetFunctionalOption("UseImportOfGoodsFromCustomsUnion") Then
		ChoiceParametersArray.Add(
			New ChoiceParameter("ProcessingInEAEUCountries", True));
	EndIf;

	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	

	ArrayOfSelectParameterRelationships = New Array;

	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));

	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));

	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));

	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));

	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.CostAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
EndProcedure


#EndRegion

// The report of the processor and the order to the processor are being checked
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, DocumentObject.SubcontractorReport2_5 - document being checked
// 	Cancel - Boolean - The flag of failure
//
Procedure CheckComplianceOfProcessorSReportsWithOrderToProcessor(Object, Cancel) Export
	
	QueryText =
	"SELECT
	|	SourceTable1.Ref AS Ref,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.Organization = &Organization
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS Organization,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.Department = &Department
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS Department,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.Partner = &Partner
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS Partner,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.Counterparty = &Counterparty
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS Counterparty,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.Contract = &Contract
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS Contract,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.ProcessingServices = &ProcessingServices
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS ProcessingServices,
	|	MAX(CASE
	|		WHEN NOT SourceTable1.GroupCosts = &GroupCosts
	|			THEN TRUE
	|		ELSE FALSE
	|	END)                 AS GroupCosts
	|FROM
	|	&SourceTable1 AS SourceTable1
	|
	|WHERE
	|	SourceTable1.Posted
	|	AND NOT &SubcontractOrder = VALUE(Document.SubcontractOrder2_5.EmptyRef)
	|	AND &SelectionOnBasisOf_1
	|
	|GROUP BY
	|	SourceTable1.Ref
	|";
	
	Query = New Query;
	
	If TypeOf(Object) = Type("DocumentObject.SubcontractorReport2_5") Then
		
		QueryText = StrReplace(QueryText, "&SourceTable1", "Document.SubcontractOrder2_5");
		QueryText = StrReplace(QueryText, "&SelectionOnBasisOf_1", "SourceTable1.Ref = &SubcontractOrder");
		
		Query.SetParameter("SubcontractOrder", Object.SubcontractOrder);
		
	Else
		
		QueryText = StrReplace(QueryText, "&SourceTable1", "Document.SubcontractorReport2_5");
		QueryText = StrReplace(QueryText, "&SelectionOnBasisOf_1", "SourceTable1.SubcontractOrder = &SubcontractOrder");
		
		Query.SetParameter("SubcontractOrder", Object.Ref);
		
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Organization",             Object.Organization);
	Query.SetParameter("Department",           Object.Department);
	Query.SetParameter("Partner",                 Object.Partner);
	Query.SetParameter("Counterparty",              Object.Counterparty);
	Query.SetParameter("Contract",                 Object.Contract);
	Query.SetParameter("ProcessingServices",     Object.ProcessingServices);
	Query.SetParameter("GroupCosts",       Object.GroupCosts);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Template = NStr("vi = 'Trong ""%1"" giá trị trường ""%2"" khác với giá trị đã chỉ ra trong đơn hàng.';
						|ru = 'В ""%1"" значение поля ""%2"" отличается от указанного в заказе.';
						|en = 'The ""%2"" field value in ""%1"" is different from the value specified in the order.'; fa = 'The ""%2"" field value in ""%1"" is different from the value specified in the order.';
						|it = 'In ""%1"" il valore del campo ""%2"" differisce da quanto indicato nell''ordine.';
						|pl = 'W ""%1"" wartość pola ""%2"" różni się od podanego w zamówieniu.';
						|tr = '""%1"" içinde ""%2"" alanının değeri siparişte belirtilenden farklıdır.'");
		
		If TypeOf(Object) = Type("DocumentObject.SubcontractorReport2_5") Then
			SubcontractorReport = Object.Ref;
		Else
			SubcontractorReport = Selection.Ref;
		EndIf;
		
		If Selection.Organization Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
			Common.MessageToUser(
				MessageText,,
				"Organization",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.GroupCosts Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Gom nhóm chi phí';
																			|ru = 'Группировка затрат';
																			|en = 'Cost grouping'; fa = 'گروه‌بندی بها';
																			|it = 'Raggruppamento dei costi';
																			|pl = 'Grupowanie kosztów ';
																			|tr = 'Gider gruplandırması'"));
			Common.MessageToUser(
				MessageText,,
				"GroupCosts",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.Department Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Bộ phận';
																			|ru = 'Подразделение';
																			|en = 'Business unit'; fa = 'Business unit';
																			|it = 'Reparto';
																			|pl = 'Dział';
																			|tr = 'Departman'"));
			Common.MessageToUser(
				MessageText,,
				"Department",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.Partner Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Bạn hàng';
																			|ru = 'Партнер';
																			|en = 'Partner'; fa = 'شریک تجاری';
																			|it = 'Partner';
																			|pl = 'Partner';
																			|tr = 'İş ortağı'"));
			Common.MessageToUser(
				MessageText,,
				"Partner",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.Counterparty Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
			Common.MessageToUser(
				MessageText,,
				"Counterparty",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.Contract Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Hợp đồng';
																			|ru = 'Договор';
																			|en = 'Contract'; fa = 'قرارداد';
																			|it = 'Contratto';
																			|pl = 'Umowa';
																			|tr = 'Sözleşme'"));
			Common.MessageToUser(
				MessageText,,
				"Contract",
				"Object",
				Cancel);
			
		EndIf;
		
		If Selection.ProcessingServices Then
			
			MessageText = StrTemplate(Template, SubcontractorReport, NStr("vi = 'Dịch vụ gia công';
																			|ru = 'Услуги по переработке';
																			|en = 'Subcontracting services'; fa = 'خدمات پیمانکاری فرعی';
																			|it = 'Servizi di lavorazione';
																			|pl = 'Usługi przetwarzania ';
																			|tr = 'İşleme hizmetleri'"));
			Common.MessageToUser(
				MessageText,,
				"ProcessingServices",
				"Object",
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function CostGroupPresentation(Val CostGroupParameters, Val GroupCosts, Val ManufacturedProduct, Val FieldNameCostGroup) Export
	
	GroupPresentation = "";
	
	SetPrivilegedMode(True);
	
	If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM Then
		
		TheStructureOfTheSearch = New Structure(FieldNameCostGroup, CostGroupParameters[FieldNameCostGroup]);
		StringsList = ManufacturedProduct.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			Return "";
		EndIf;
		LineProducts = StringsList[0];
		If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts Then
			GroupPresentation = ProductsClientServer.ProductPresentation(
				String(LineProducts.Products),
				String(LineProducts.Characteristic),,,
				String(LineProducts.Purpose));
			
		Else
			GroupPresentation = String(LineProducts.BillOfMaterials);
		EndIf;
	Else
		
		If ValueIsFilled(CostGroupParameters.ReferenceOrder) Then
			
				TextTemplate1 = NStr("vi = 'Công đoạn số %1 ngày %2 (%3)';
									|ru = 'Этап № %1 от %2 (%3)';
									|en = 'Stage No. %1 dated %2 (%3)'; fa = 'Stage No. %1 dated %2 (%3)';
									|it = 'Fase №%1 di %2 (%3)';
									|pl = 'Etap nr %1 z dn. %2 (%3)';
									|tr = '%2 tarihli %1 numaralı aşama (%3)'");
			
			If ValueIsFilled(CostGroupParameters.BillOfMaterials) Then
				BillOfMaterials = CostGroupParameters.BillOfMaterials;
			Else
				BillOfMaterials = NStr("vi = 'không có bảng kê chi tiết các nguồn lực sản xuất';
										|ru = 'без спецификации';
										|en = 'without bill of materials'; fa = 'without bill of materials';
										|it = 'senza specifica';
										|pl = 'bez specyfikacji';
										|tr = 'ürün reçetesiz'");
			EndIf;
			
			DetailsOfOrder = Common.ObjectAttributesValues(CostGroupParameters.ReferenceOrder, "Number,Date");
			GroupPresentation = StrTemplate(TextTemplate1,
											ObjectsPrefixesClientServer.NumberForPrinting(DetailsOfOrder.Number, False, True),
											Format(DetailsOfOrder.Date, "DLF=D"),
											BillOfMaterials);
			
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return GroupPresentation;

EndFunction 

// Checks whether the order can be closed
//
// Parameters:
//  Object	 - DocumentObject - controlled document.
//  Cancel	 - Boolean							 - the opt-Out parameter.
//
Procedure PerformOrderControlAfterConducting(Object, Cancel) Export
	
	If Object.Status <> Enums.TollingOrderStatuses.Closed Then
		Return;
	EndIf;
	
	QueryText =
		"SELECT
		|	ShippingOrdersTurnover.ReferenceOrder AS SalesOrder
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|WHERE
		|	&MonitorFullDevelopment
		|	AND ((ShippingOrdersTurnover.OrderedQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover) > 0
		|		OR (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|			ShippingOrdersTurnover.IssuedQuantityTurnover) > 0)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsForIssueBalance.DocumentShipments
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments = &Ref) AS GoodsForIssueBalance
		|WHERE
		|	&MonitorFullDevelopment
		|	AND GoodsForIssueBalance.ToShipBalance + GoodsForIssueBalance.AssembledBalance > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Calculations.Currency AS Currency,
		|	-Calculations.AmountDueBalance AS AmountDueBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS Calculations
		|WHERE
		|	&MonitorCalculations
		|	AND Calculations.AmountDueBalance < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseOrdersBalance.PurchaseOrder AS PurchaseOrder
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &Ref) AS PurchaseOrdersBalance
		|WHERE
		|	&MonitorFullDevelopment
		|	AND (PurchaseOrdersBalance.OrderedBalance > 0
		|	OR PurchaseOrdersBalance.ToRegisterBalance > 0
		|	OR PurchaseOrdersBalance.ToReceiveBalance > 0)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &Ref) AS GoodsToReceiveBalance
		|WHERE
		|	&MonitorFullDevelopment
		|	AND GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance + GoodsToReceiveBalance.AcceptsBalance > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SubcontractorServices.SumBalance AS Sum
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &Ref) AS SubcontractorServices
		|WHERE
		|	SubcontractorServices.SumBalance > 0
		|	AND &MonitorFullDevelopment
		|	AND TRUE";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &Ref";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	MonitorFullDevelopment =
		GetFunctionalOption("DoNotCloseTollingOrdersWithoutCompleteFulfillment2_5")
			And TypeOf(Object) = Type("DocumentObject.SubcontractOrder2_5")
		Or False;
	
	MonitorCalculations =
		(GetFunctionalOption("DoNotCloseTollingOrdersWithoutCompletePayment2_5")
			And TypeOf(Object) = Type("DocumentObject.SubcontractOrder2_5")
		Or False)
		And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts
		And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;

	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("MonitorFullDevelopment", MonitorFullDevelopment);
	Query.SetParameter("MonitorCalculations", MonitorCalculations);
	Result = Query.ExecuteBatch();
	
	SampleShipment    = Result[0].Select();
	SampleCalculations_     = Result[1].Select();
	SampleReceipt = Result[2].Select();
	SampleReports      = Result[3].Select();
	
	If SampleShipment.Next() Then 
		ErrorText = NStr("vi = 'Nguyên vật liệu theo đơn hàng ""%1"" đã được giao chưa đầy đủ.
							|Chỉ có thể đóng đơn hàng với các dòng đã giao/hủy bỏ toàn bộ';
							|ru = 'Сырье и материалы по заказу ""%1"" отгружены не полностью.
							|Закрытие заказа возможно только с полностью отгруженными/отмененными строками';
							|en = 'Raw and consumable materials by the ""%1"" order are not shipped fully.
							|You can close the order only for fully shipped/canceled lines'; fa = 'Raw and consumable materials by the ""%1"" order are not shipped fully.
							|You can close the order only for fully shipped/canceled lines';
							|it = 'Le materie prime e i materiali per l''ordine ""%1"" non sono stati scaricati completamente.
							|La chiusura dell''ordine è possibile solo quando tutte le righe sono scaricate/annullate';
							|pl = 'Surowiec i materiały na zamówienie ""%1"" są wysłane nie w całości.
							|Zamknięcie zamówienia jest możliwe tylko z całkowicie wysłanymi/anulowanymi wierszami';
							|tr = '""%1"" siparişine ilişkin hammaddeler ve sarf malzemeleri tümüyle sevk edilmedi.
							|Siparişin sonlanması sadece tümüyle sevk edilen/iptal edilen satırlarla mümkündür'");
							
		ErrorText = StrTemplate(ErrorText, Object.Ref);
		Common.MessageToUser(ErrorText, Object.Ref,,, Cancel);
	EndIf;
	
	If SampleReceipt.Next() Then 
		ErrorText = NStr("vi = 'Đã tiếp nhận không đầy đủ sản phẩm theo đơn hàng ""%1"".
							|Chỉ có thể đóng đơn hàng với các dòng đã tiếp nhận/hủy bỏ toàn bộ';
							|ru = 'Продукция по заказу ""%1"" поступила не полностью.
							|Закрытие заказа возможно только с полностью поступившими/отмененными строками';
							|en = 'Products against the ""%1"" order were not fully received.
							|You can close the order only with fully received/canceled lines'; fa = 'Products against the ""%1"" order were not fully received.
							|You can close the order only with fully received/canceled lines';
							|it = 'I prodotti per l''ordine ""%1"" non sono tutti arrivati.
							|La chiusura dell''ordine è possibile solo quando tutte le righe sono arrivate/annullate';
							|pl = 'Wiersze pozycji na zamówienie ""%1""wpłynęli nie w całości.
							|Zamknięcie zamówienia jest możliwe tylko z całkowicie otrzymanymi/anulowanymi wierszami';
							|tr = '""%1"" siparişine ilişkin imal edilen ürünler tümüyle alınmadı.
							|Siparişin sonlanması sadece tümüyle alınan/iptal edilen satırlarla mümkündür'");
		
		ErrorText = StrTemplate(ErrorText, Object.Ref);
		
		Common.MessageToUser(ErrorText, Object.Ref,,, Cancel);
	EndIf;
	
	If SampleCalculations_.Next() Then 
		ErrorText = NStr("vi = 'Chưa hoàn thành thanh toán theo đơn hàng ""%1"".
		|Để đóng đơn hàng, cần thanh toán %2 %3
		|Chỉ có thể đóng đơn hàng với các dòng đã thanh toán/hủy bỏ toàn bộ';
		|ru = 'Расчеты по заказу ""%1"" не завершены.
		|Для закрытия заказа требуется оплата %2 %3
		|Закрытие заказа возможно только с полностью оплаченными/отмененными строками';
		|en = 'Settlements of order ""%1"" are not completed.
		|To close the order, payment is required %2 %3
		|You can close order only when all lines are paid/canceled'; fa = 'Settlements of order ""%1"" are not completed.
		|To close the order, payment is required %2 %3
		|You can close order only when all lines are paid/canceled';
		|it = 'Le regolazioni dei conti per l''ordine ""%1"" non sono terminate.
		|Per la chiusura dell''ordine è necessario un pagamento %2 %3
		|La chiusura dell''ordine è possibile solo quando tutte le righe sono pagate/annullate';
		|pl = 'Obliczenia z tytułu zamówienia ""%1"" nie są zakończone.
		|W celu zamknięcia zamówienia jest konieczna płatność %2 %3
		|Zamknięcie zamówienia jest możliwe tylko z całkowicie opłaconymi/anulowanymi wierszami';
		|tr = '""%1"" siparişine ilişkin hesaplama tamamlanmadı.
		|Siparişin sonlanması için %2 %3 ödeme gerekmektedir.
		|Siparişin sonlanması sadece tümüyle ödenen/iptal edilen satırlarla mümkündür'");
		
		ErrorText = StrTemplate(ErrorText, 
							Object.Ref, 
							String(SampleCalculations_.AmountDueBalance), 
							String(SampleCalculations_.Currency));
							
		Common.MessageToUser(ErrorText, Object.Ref,,, Cancel);
	EndIf;
	
	If SampleReports.Next() Then 
		ErrorText = NStr("vi = 'Chưa lập tất cả bảng kê cho người nhận gia công.
		|Để đóng đơn hàng, cần lập bảng kê là %1 %2.
		|Chỉ có thể đóng đơn hàng với giá trị dịch vụ đã điều chỉnh';
		|ru = 'Не все отчеты переработчику сформированы.
		|Для закрытия заказа требуется оформление отчетов на %1 %2.
		|Закрытие заказа возможно только с откорректированной стоимостью услуг';
		|en = 'Not all subcontractor reports are generated.
		|To close the order, it is required to generate reports for %1 %2. 
		|The order can be closed only with the corrected service cost'; fa = 'Not all subcontractor reports are generated.
		|To close the order, it is required to generate reports for %1 %2. 
		|The order can be closed only with the corrected service cost';
		|it = 'Non tutti i report al subfornitore sono stati creati.
		|Per la chiusura dell''ordine è necessaria la creazione degli ordini a %1 %2.
		|La chiusura dell''ordine è possibile solo con un costo dei servizi ricondizionato';
		|pl = 'Nie wszystkie raporty do przetwórcy są utworzone.
		|W celu zamknięcia zamówienia potrzebne jest sporządzenie raportów na %1 %2.
		|Zamknięcie zamówienia jest możliwe tylko z poprawioną wartością usług';
		|tr = 'Fason üretici hizmetleri bildirimlerinin tümü oluşturulmadı.
		|Siparişin sonlanması için %1 %2 bildirimlerin oluşturulması gerekmektedir.
		|Siparişin sonlanması sadece düzeltilmiş hizmet maliyeti ile mümkündür'");
		
		ErrorText = StrTemplate(ErrorText, String(SampleReports.Sum), String(Object.Currency));
		Common.MessageToUser(ErrorText, Object.Ref,,, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

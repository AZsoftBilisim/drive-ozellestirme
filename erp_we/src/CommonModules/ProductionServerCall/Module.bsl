////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Production"
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overridable handler for getting data for selecting the business structure reference list.
//
// Parameters:
//  ChoiceData - ValueList - selection values.
//  Parameters - Structure - the selection parameters.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure EnterpriseStructureProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	If ValueIsFilled(Parameters.SearchString) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED TOP 51
		|	BusinessStructure.Ref AS Ref,
		|	BusinessStructure.DeletionMark AS DeletionMark,
		|	BusinessStructure.Description AS Description,
		|	CASE
		|		WHEN BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.NotValid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS NotValid,
		|	TRUE AS SelectionByCode,
		|	BusinessStructure.Code AS Code
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.Code LIKE &Text
		|	AND NOT BusinessStructure.DeletionMark
		|	AND (BusinessStructure.ProductionDispatcherBusinessUnit
		|	OR BusinessStructure.ProductionBusinessUnit)
		|
		|UNION ALL
		|
		|SELECT TOP 51
		|	BusinessStructure.Ref AS Ref,
		|	BusinessStructure.DeletionMark AS DeletionMark,
		|	BusinessStructure.Description AS Description,
		|	CASE
		|		WHEN BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.NotValid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS NotValid,
		|	FALSE,
		|	BusinessStructure.Code
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.Description LIKE &Text
		|	AND NOT BusinessStructure.DeletionMark
		|	AND (BusinessStructure.ProductionDispatcherBusinessUnit
		|	OR BusinessStructure.ProductionBusinessUnit)
		|
		|ORDER BY
		|	Description";
		
		Query.SetParameter("Text", "%" + TrimAll(Parameters.SearchString) + "%");
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		ChoiceData = New ValueList;
		While Selection.Next() Do
			TemplateOfPresentation = "%1 (%2)";
			If Selection.SelectionByCode Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation, Selection.Code, Selection.Description);
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation, Selection.Description, Selection.Code);
			EndIf;
			If Selection.NotValid Then 
				Item = New Structure;
				Item.Insert("Value", Selection.Ref);
				Item.Insert("DeletionMark", Selection.DeletionMark);
				WarningText = NStr("vi = 'Đã chọn bộ phận không còn hiệu lực.';
									|ru = 'Выбрано недействующее подразделение.';
									|en = 'An inactive business unit is selected.'; fa = 'An inactive business unit is selected.';
									|it = 'Выбрано недействующее подразделение.';
									|pl = 'An inactive business unit is selected.';
									|tr = 'Aktif olmayan bir departman seçilmiş.'"); 
				Item.Insert("Warning", WarningText);
				ChoiceData.Add(Item, Presentation);
			Else
				ChoiceData.Add(Selection.Ref, Presentation);
			EndIf;
		EndDo; 
								
	EndIf;
	
EndProcedure

// Returns parameters of the production division
//
// Parameters:
//  Department	- CatalogRef.BusinessStructure - The Department that you want to get parameters for.
//
// Returns:
//   Structure   - contains the parameters of the production unit.
//
Function ProductionBusinessUnitDescription(Department) Export
	
	Parameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	Return Parameters;
	
EndFunction

// Determines whether production version 2.1 is used
// 
// Returns:
//   Boolean - True if production version 2.1 is used
//
Function ProductionIsUsed21() Export
	
	Return GetFunctionalOption("UseProductionManagement");
	
EndFunction

// Determines whether production version 2.2 is used
// 
// Returns:
//   Boolean - True if production version 2.2 is used
//
Function ProductionIsUsed22() Export
	
	Return GetFunctionalOption("UseProductionManagement2_2");
	
EndFunction

#Region BackflushProduction_

// Arrange production without an order based on.
// 
// Parameters:
//  ReferencesArrray - Array
//  DocumentParameters_ - See ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders
// 
// Returns:
//  Structure - To Arrange Production Without An Order On The Basis Of:
//  * FormObject - DocumentObject
//  * DocumentType - String
//  * HasErrors - Boolean -
//  * DocumentsList - ValueList -
//  * ErrorsArray - FixedArray -
//
Function ToArrangeProductionWithoutOrderOnBasisOf(ReferencesArrray, DocumentParameters_) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SalesOrder.Ref                                    AS Ref,
	|	SalesOrder.Status                                    AS Status,
	|	NOT SalesOrder.Posted                               AS ThereAreErrorsPosted,
	|	SalesOrder.Status =
	|			VALUE(Enum.SalesOrderStatuses.NotApproved)
	|		AND &UseAdvancedFeaturesOfSalesOrder AS ThereAreErrorsStatus
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Ref IN (&ReferencesArrray)
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialProviderOrder.Ref                                           AS Ref,
	|	MaterialProviderOrder.Status                                           AS Status,
	|	NOT MaterialProviderOrder.Posted                                      AS ThereAreErrorsPosted,
	|	MaterialProviderOrder.Status IN (
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.Approved)) AS ThereAreErrorsStatus
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder
	|WHERE
	|	MaterialProviderOrder.Ref IN (&ReferencesArrray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0                                                              AS CostGroupNumber,
	|	CustomerOrderGoods.Ref.Organization                          AS Organization,
	|	VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts) AS GroupCosts,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)         AS Department,
	|	CASE
	|		WHEN CustomerOrderGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|		ELSE VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|	END                                                          AS DirectionOfProductionIssue,
	|	CASE
	|		WHEN CustomerOrderGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN CustomerOrderGoods.Department
	|		ELSE CustomerOrderGoods.Warehouse
	|	END                                                          AS Recipient,
	|	CustomerOrderGoods.Products                                AS Products,
	|	CustomerOrderGoods.Characteristic                              AS Characteristic,
	|	CustomerOrderGoods.Series                                       AS Series,
	|	CASE
	|		WHEN CustomerOrderGoods.WithAssignment
	|			THEN CustomerOrderGoods.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                          AS Purpose,
	|	CustomerOrderGoods.Ref.LineOfBusiness              AS LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)        AS BillOfMaterials,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS AllocatedAccordingToRule,
	|	CustomerOrderGoods.Count                                  AS Count,
	|	TRUE                                                         AS RecordCostsByADocument,
	|	FALSE                                                           AS ErrorInModelSettings
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref IN (&ReferencesArrray)
	|	AND CustomerOrderGoods.Ref.Posted
	|	AND (NOT CustomerOrderGoods.Ref.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
	|		OR NOT &UseAdvancedFeaturesOfSalesOrder)
	|	AND NOT CustomerOrderGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND NOT CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|UNION ALL
	|
	|SELECT
	|	0                                                              AS CostGroupNumber,
	|	GiverSOrderProducts.Ref.Organization                      AS Organization,
	|	VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments) AS GroupCosts,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)         AS Department,
	|	CASE
	|		WHEN GiverSOrderProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|		ELSE VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|	END                                                          AS DirectionOfProductionIssue,
	|	CASE
	|		WHEN GiverSOrderProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN GiverSOrderProducts.Department
	|		ELSE GiverSOrderProducts.Warehouse
	|	END                                                          AS Recipient,
	|	GiverSOrderProducts.Products                            AS Products,
	|	GiverSOrderProducts.Characteristic                          AS Characteristic,
	|	GiverSOrderProducts.Series                                   AS Series,
	|	CASE
	|		WHEN GiverSOrderProducts.WithAssignment
	|			AND Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered =
	|				VALUE(Enum.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder)
	|			THEN GiverSOrderProducts.Ref.Purpose
	|		WHEN GiverSOrderProducts.WithAssignment
	|			THEN GiverSOrderProducts.Ref.Contract.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                          AS Purpose,
	|	GiverSOrderProducts.Ref.LineOfBusiness          AS LineOfBusiness,
	|	GiverSOrderProducts.BillOfMaterials                            AS BillOfMaterials,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS AllocatedAccordingToRule,
	|	GiverSOrderProducts.Count                              AS Count,
	|	TRUE                                                         AS RecordCostsByADocument,
	|	FALSE                                                           AS ErrorInModelSettings
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrderProducts
	|	
	|	LEFT JOIN Constants AS Constants
	|	ON TRUE
	|
	|WHERE
	|	GiverSOrderProducts.Ref IN (&ReferencesArrray)
	|	AND GiverSOrderProducts.Ref.Posted
	|	AND NOT GiverSOrderProducts.Ref.Status IN (
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved),
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.Approved))
	|	AND NOT GiverSOrderProducts.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT GiverSOrderProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND NOT GiverSOrderProducts.Canceled
	|";
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Results = Query.ExecuteBatch();
	
	AcceptableStatusesOfCustomerSOrder = New Array;
	AcceptableStatusesOfCustomerSOrder.Add(Enums.SalesOrderStatuses.ToSupply);
	AcceptableStatusesOfCustomerSOrder.Add(Enums.SalesOrderStatuses.ToShip);
	AcceptableStatusesOfCustomerSOrder.Add(Enums.SalesOrderStatuses.Closed);
	AcceptableStatusesOfGiverSOrder = New Array;
	AcceptableStatusesOfGiverSOrder.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
	AcceptableStatusesOfGiverSOrder.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
	AcceptableStatusesOfGiverSOrder.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
	OrdersWithError = Results[0].Unload();
	For Each CurrentData In OrdersWithError Do
		
		If TypeOf(CurrentData.Ref) = Type("DocumentRef.SalesOrder")Then
			AcceptableStatuses = AcceptableStatusesOfCustomerSOrder;
		ElsIf TypeOf(CurrentData.Ref) = Type("DocumentRef.MaterialProviderOrder2_5")Then
			AcceptableStatuses = AcceptableStatusesOfGiverSOrder;
		Else
			AcceptableStatuses = New Array;
		EndIf;
		
		CheckParameters                          = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
		CheckParameters.Status                   = CurrentData.Status;
		CheckParameters.ThereAreErrorsPosted       = CurrentData.ThereAreErrorsPosted;
		CheckParameters.ThereAreErrorsStatus         = CurrentData.ThereAreErrorsStatus;
		CheckParameters.ArrayOfValidStatuses = AcceptableStatuses;
		CheckParameters.InterruptExecution      = False;
		
		TMCommonUse.CheckPossibilityOfInputBasedOnParameters(CurrentData.Ref, CheckParameters);
		
	EndDo;
	
	For Each CurrentData In Results[Results.UBound()].Unload() Do
		StructureProductLine = ProductionClientServer.StructureProductLine();
		FillPropertyValues(StructureProductLine, CurrentData);
		DocumentParameters_.ProductsAccordingToSpecification.Add(StructureProductLine);
	EndDo;
	
	Return DataProcessors.RegisterBackflushProduction.GenerateDocumentsByParameters(DocumentParameters_);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region CalculationOfCostShares

Function AvailableDecryptionOfCalculationOfShareOfCost(MethodOfAllocatingFinishedProductCosts) Export
	
	If MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost Then
		If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
			ThereIsAccess = AccessRight("View", Metadata.InformationRegisters.ItemsPrices25);
		Else
			ThereIsAccess = AccessRight("View", Metadata.InformationRegisters.ItemsPrices);
		EndIf;
	Else
		ThereIsAccess = True;
	EndIf;
	
	Return ThereIsAccess;
	
EndFunction

#EndRegion

Function AvailableWorkplaceOrdersProcessors() Export

	If GetFunctionalOption("UseProduction")
		And Users.RolesAvailable("UseWorkplaceTollingOrders") Then
		Return True;
	EndIf;

	Return False;
	
EndFunction

Function ParametersForCreatingProductAndMaterialMovementBasedOn(AnArrayOfOrders, BusinessOperation) Export
	
	ObjectsOfBases = AnArrayOfOrders;
	
	HeaderAttributes = Documents.MovementOfProductsAndMaterials.InvoiceFillingData(ObjectsOfBases, New Structure("BusinessOperation", BusinessOperation));
	CheckResults = Documents.MovementOfProductsAndMaterials.CheckInvoiceFillingData(HeaderAttributes);
	
	BasisParameters = New Structure;
	If HeaderAttributes.ByReferences Then
		BasisParameters.Insert("HeaderAttributes", HeaderAttributes);
		BasisParameters.Insert("AnArrayOfOrders",  ObjectsOfBases);
	Else
		BasisParameters.Insert("ObjectsOfBases", ObjectsOfBases);
		BasisParameters.Insert("BusinessOperation", HeaderAttributes.BusinessOperation);
	EndIf;
	
	Return New Structure("Basis, CheckResults", BasisParameters, CheckResults);
	
EndFunction

Function DocumentsMovementOfProductsAndMaterialsByParameters(DocumentParameters_) Export
	
	// StandardSubsystems.PerformanceMeasurement
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.ProductionServerCall.DocumentsMovementOfProductsAndMaterialsByParameters");
	// End StandardSubsystems.PerformanceMeasurement
	
	ObjectsArray = Documents.MovementOfProductsAndMaterials.DocumentsOnParameters(DocumentParameters_);
	Result = New Structure;
	
	If ObjectsArray.Count() = 1 Then
		ValueToFormData(ObjectsArray[0], DocumentParameters_.FormObject);
		Result.Insert("OpenNewForm_");
	Else
		
		CreatedDocuments = New Array;
		For Each CurDocument In ObjectsArray Do
			CurDocument.Write(DocumentWriteMode.Write);
			CreatedDocuments.Add(CurDocument.Ref);
		EndDo;
		
		If CreatedDocuments.Count() > 1 Then
			
			FormParameters = New Structure("DataKey, VisibleColumns, UpdateEvents",
				"ProductionWithoutOrderOnBasisOf", New Array, New Array);
			
			FormParameters.VisibleColumns.Add("Number");
			FormParameters.VisibleColumns.Add("Date");
			FormParameters.VisibleColumns.Add("ValueType");
			FormParameters.VisibleColumns.Add("BusinessOperation");
			FormParameters.VisibleColumns.Add("Organization");
			FormParameters.VisibleColumns.Add("Department");
			FormParameters.VisibleColumns.Add("LineOfBusiness");
			If GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements") Then
				FormParameters.VisibleColumns.Add("Status");
			EndIf;
			FormParameters.VisibleColumns.Add("More");
			
			FormParameters.UpdateEvents.Add("Write_MovementOfProductsAndMaterials");
			
			Result.Insert("FormName", "CommonForm.CreatedDocumentForm");
			Result.Insert("Parameters", FormParameters);
			
			Owner = Users.AuthorizedUser();
			SetPrivilegedMode(True);
			Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParameters.DataKey);
			SetPrivilegedMode(False);
			
		EndIf;
		
		Result.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;
	
	// StandardSubsystems.PerformanceMeasurement
	OperationsCount = DocumentParameters_.ObjectsOfBases.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, OperationsCount);
	// End StandardSubsystems.PerformanceMeasurement
	
	Return Result;
	
	
EndFunction

Function CreateActOfCompletedInternalWorksVerificationOfGrounds(ObjectsOfBases) Export
	
	QueriesTexts = New Array;
	QueryText =
	"
	|SELECT
	|	GoodsTable.Ref                          AS Ref,
	|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
	|	MAX(GoodsTable.InternalSubcontracting) AS InternalSubcontracting,
	|	MAX(GoodsTable.MaterialProviderCompany)    AS MaterialProviderCompany
	|INTO CostGroups
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsOfBases)
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.CostGroupNumber
	|
	|INDEX BY
	|	Ref,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Recipients of output products (production without an order)
	|SELECT
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN Attributes.Organization
	|	END								AS Organization,
	|	Attributes.LineOfBusiness	AS LineOfBusiness,
	|	Attributes.ProductionIssueForActivity		AS TransferForActivity,
	|	TableOfGoods.Recipient			AS Department
	|INTO TTProducts_1
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		LEFT JOIN Document.BackflushProduction AS Attributes
	|		ON TableOfGoods.Ref = Attributes.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|
	|GROUP BY
	|	Attributes.LineOfBusiness,
	|	Attributes.ProductionIssueForActivity,
	|	TableOfGoods.Recipient,
	|	CASE
	|		WHEN TableOfGoods.InternalSubcontracting
	|			THEN TableOfGoods.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN Attributes.Organization
	|	END
	|
	|UNION ALL
	|
	// Recipients of by-products (production without an order)
	|SELECT
	|	CASE
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
	|			THEN CostGroups.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN Attributes.Organization
	|	END								AS Organization,
	|	Attributes.LineOfBusiness	AS LineOfBusiness,
	|	Attributes.ProductionIssueForActivity		AS TransferForActivity,
	|	TableOfGoods.Recipient			AS Department
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS TableOfGoods
	|	
	|	LEFT JOIN Document.BackflushProduction AS Attributes
	|	ON TableOfGoods.Ref = Attributes.Ref
	|	
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON TableOfGoods.Products = CatProducts.Ref
	|	
	|	LEFT JOIN CostGroups AS CostGroups
	|	ON CostGroups.Ref = TableOfGoods.Ref
	|	AND CostGroups.CostGroupNumber = TableOfGoods.CostGroupNumber
	|	AND CostGroups.InternalSubcontracting
	|	
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|
	|GROUP BY
	|	Attributes.LineOfBusiness,
	|	Attributes.ProductionIssueForActivity,
	|	TableOfGoods.Recipient,
	|	CASE
	|		WHEN NOT TableOfGoods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TableOfGoods.ProductOwner
	|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
	|			THEN CostGroups.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN Attributes.Organization
	|	END
	|";
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(Documents.ProductionStage2_2.TextOfRequestForVerificationOfGroundsForActsOfWork());
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	Query.Text = Query.Text + "
	|;
	|SELECT
	|	MAX(TableOfGoods.Organization)							AS Organization,
	|	MAX(TableOfGoods.LineOfBusiness)				AS LineOfBusiness,
	|	MAX(TableOfGoods.TransferForActivity)				AS TransferForActivity,
	|	MAX(TableOfGoods.Department)							AS Department,
	|	COUNT(DISTINCT TableOfGoods.Organization)				AS VariousOrganizations,
	|	COUNT(DISTINCT TableOfGoods.LineOfBusiness)	AS VariousActivities,
	|	COUNT(DISTINCT TableOfGoods.TransferForActivity)	AS VariousMovementsUnderOperation,
	|	COUNT(DISTINCT TableOfGoods.Department)				AS DifferentRecipients
	|FROM
	|	TTProducts_1 AS TableOfGoods
	|HAVING
	|	MAX(TableOfGoods.Organization) IS NOT NULL
	|";
	
	Query.SetParameter("ObjectsOfBases", ObjectsOfBases);
	
	Errors = Query.Execute().Select();
	HeaderAttributes = "Organization, LineOfBusiness, Department, TransferForActivity";
	HeaderAttributes = New Structure(HeaderAttributes);
	Result = New Structure;
	
	If Errors.Next() Then
		
		HasErrors = False;
		ErrorText = NStr("vi = 'Trong các chứng từ cơ sở, các giá trị khác nhau:';
						|ru = 'В документах-основаниях различаются значения:';
						|en = 'Values are different in base documents:'; fa = 'Values are different in base documents:';
						|it = 'Nei documenti-causali differiscono i valori:';
						|pl = 'W dokumentach podstawowych są różne wartości:';
						|tr = 'Temel belgelerde farklılık gösteren değerler:'");
		If Not Errors.VariousOrganizations = 1 Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = '- Doanh nghiệp';
													|ru = '- Организаций';
													|en = '- Companies'; fa = '- Companies';
													|it = '- Delle organizzazioni';
													|pl = '- Firmy';
													|tr = '- İş yerleri'");
			HasErrors = True;
		EndIf;
		
		If Not Errors.DifferentRecipients = 1 Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = '- Người nhận công việc';
													|ru = '- Получателей работ';
													|en = '- Work recipients'; fa = '- Work recipients';
													|it = '- Ricevitori dei lavori';
													|pl = '- Odbiorców prac';
													|tr = '- İş alıcılar'");
			HasErrors = True;
		EndIf;
		
		If Not Errors.VariousActivities = 1 Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = '- Lĩnh vực hoạt động';
													|ru = '- Направлений деятельности';
													|en = '- Lines of business'; fa = '- Lines of business';
													|it = '- Delle direzioni dell''attività';
													|pl = '- Rodzaje działalności';
													|tr = '- İş kolları'");
			HasErrors = True;
		EndIf;
		
		If Not Errors.VariousMovementsUnderOperation = 1 Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = '- Xuất xưởng theo hoạt động';
													|ru = '- Выпуска под деятельность';
													|en = '- Release for activity'; fa = '- Release for activity';
													|it = '- Release for activity';
													|pl = '- Release for activity';
													|tr = '- Faaliyetler altında çıkış'");
			HasErrors = True;
		EndIf;
		
		If HasErrors Then
			ErrorText = ErrorText + Chars.LF + NStr("vi = 'Không thể lập chứng từ!';
													|ru = 'Оформление документа невозможно!';
													|en = 'Cannot register the document.'; fa = 'Cannot register the document.';
													|it = 'La registrazione del documento è impossibile!';
													|pl = 'Sporządzenie dokumentu nie jest możliwe';
													|tr = 'Belgenin düzenlenmesi mümkün değildir!'");
			Result.Insert("HasErrors");
			Result.Insert("ErrorText", ErrorText);
		Else
			FillPropertyValues(HeaderAttributes, Errors);
		EndIf;
	Else
		ErrorText = NStr("vi = 'Thiếu dữ liệu để điền vào!';
						|ru = 'Отсутствуют данные для заполнения!';
						|en = 'No data to populate.'; fa = 'No data to populate.';
						|it = 'Sono assenti i dati per la compilazione!';
						|pl = 'Brak danych do wypełnienia!';
						|tr = 'Doldurulacak veri bulunmamaktadır!'");
		Result.Insert("HasErrors");
		Result.Insert("ErrorText", ErrorText);
	EndIf;
	
	Result.Insert("HeaderAttributes", HeaderAttributes);
	
	Return Result;
	
EndFunction

#EndRegion

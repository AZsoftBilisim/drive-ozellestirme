#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
// 		NewStatus - String - Name of the status to be set for the document
// 		AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//								Structure constructor: Order a server.Structurecorrectionslist of orders().
//
// Returns:
// 		Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.RMOrderStatuses[NewStatus];
	
	If MeaningOfNewStatus = Enums.RMOrderStatuses.Running Then
		StartDateActual = CurrentSessionDate();
	ElsIf MeaningOfNewStatus = Enums.RMOrderStatuses.Closed Then
		ActualCompletionDate = CurrentSessionDate();
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RMOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction // Set the status()

// Corrects lines for which no write-off or shipment was issued, or there are discrepancies for measured items.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: order Server.Structurecorrectionslist of orders().
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines And Not ParametersStructure.CorrectMeasuringGoods Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	AdjustMaterials = (ParametersStructure.CancelUnprocessedLines Or ParametersStructure.CorrectMeasuringGoods)
		And (ParametersStructure.TabularSectionName = "Goods" Or ParametersStructure.TabularSectionName = "MaterialsAndWorks");
	AdjustLaborCosts = ParametersStructure.CancelUnprocessedLines
		And (ParametersStructure.TabularSectionName = "Goods" Or ParametersStructure.TabularSectionName = "LaborCosts");
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure("Canceled, BatchesIndicationStatus", True, 0);
		
		If AdjustMaterials Then
			
			For Each LineProducts_ In MaterialsAndWorks Do
				If Not LineProducts_.Canceled Then
					
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
					
				EndIf;
			EndDo;
			
		EndIf;
		
		If AdjustLaborCosts Then
			
			For Each LineProducts_ In LaborCosts Do
				If Not LineProducts_.Canceled Then
					
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
					
				EndIf;
			EndDo;
			
		EndIf;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	EndIf;
	
	If AdjustMaterials Then
		
		FillParameters = OrdersServer.FillOptionsForCancelingRows();
		FillParameters.RegisterManager  = AccumulationRegisters.InventoryConsumptionOrders;
		FillParameters.TabularSectionName = "MaterialsAndWorks";
		FillParameters.DataPaths.Insert("Purpose", "Purpose");
		
		CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
		CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
			And ParametersStructure.CorrectMeasuringGoods;
		CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
		
		NumberOfAdjustedRows = NumberOfAdjustedRows
			+ OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions).RowsCount;
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RMOrder));
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
		
	EndIf;
	
	If AdjustLaborCosts Then
		
		NumberOfAdjustedRows = NumberOfAdjustedRows
			+ Documents.RMOrder.CancelUnfulfilledLaborLines(ThisObject, True);
		
	EndIf;
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	
EndFunction

// Checks whether the repair keys are filled in correctly in the table part
//
// Parameters:
// 		TabularSection - TabularSection - Table part of the document object.
//
Procedure MatchRepairKeysInTablePart(TabularSection) Export
	
	MatchingRepairs = Undefined;
	
	If Not AdditionalProperties.Property("MatchingRepairs", MatchingRepairs)
		Or MatchingRepairs = Undefined Then
		
		MatchingRepairs = New Map;
		For Each Repair In RM Do
			MatchingRepairs.Insert(Repair.RMCode, True);
		EndDo;
		AdditionalProperties.Insert("MatchingRepairs", MatchingRepairs);
		
	EndIf;
	
	StructureOfUnmappedRepairs = New Structure("RMCode", 0);
	
	For Each String In TabularSection Do
		If ValueIsFilled(String.RMCode) And MatchingRepairs.Get(String.RMCode)=Undefined Then
			FillPropertyValues(String, StructureOfUnmappedRepairs);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	Status = Enums.RMOrderStatuses.Created;
	MaximumRowCodeItems = 0;
	MaximumRowCodeOfLaborCosts = 0;
	Purpose = Undefined;
	
	For Each LineProducts_ In MaterialsAndWorks Do
		
		LineProducts_.Canceled = False;
		LineProducts_.RowCode = 0;
		
	EndDo;
	
	For Each LineProducts_ In LaborCosts Do
		
		LineProducts_.RowCode = 0;
		
	EndDo;
	
	LaborCostsAreAvailable = False;
	LaborCosts.Clear();
	
	FillParameters = Documents.RMOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ConsumptionForActivity, FillParameters);
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.Assets")
		Or FillInDataType = Type("CatalogRef.SubAssets") Then
			
		FillInDocumentBasedOnObjectOfOperation(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.RMRequest") Then
		
		FillInDocumentOnBasisOfDefectRegistration(FillingData);
		
	EndIf;
	
	FillParameters = Documents.RMOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ConsumptionForActivity, FillParameters);
	
	InitializeDocument(FillingData);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SetKeysInRowsOfTablePart(RM, "RMCode", MaximumRMCode);
	SetKeysInRowsOfTablePart(MaterialsAndWorks, "RowCode", MaximumRowCodeItems);
	SetKeysInRowsOfTablePart(LaborCosts, "RowCode", MaximumRowCodeOfLaborCosts);
	
	MatchRepairKeysInTablePart(MaterialsAndWorks);
	MatchRepairKeysInTablePart(LaborCosts);
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "MaterialsAndWorks";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	DestinationPattern = Documents.RMOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, "LineOfBusiness", Cancel);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RMOrder));
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.RMOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Department, ConsumptionForActivity);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PerformOrderControlAfterConducting(Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	CheckedAttributes.Add("RM");
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("MaterialsAndWorks.Warehouse");
	
	Documents.RMOrder.NamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If Status = Enums.RMOrderStatuses.Created Then
		NotCheckedAttributeArray.Add("StartDate");
		NotCheckedAttributeArray.Add("CompletedOn");
	EndIf;

	If Status = Enums.RMOrderStatuses.Running Then
		
		NotCheckedAttributeArray.Add("ActualCompletionDate");
		
	ElsIf Status = Enums.RMOrderStatuses.Created
		Or Status = Enums.RMOrderStatuses.ForCompletion Then
		
		NotCheckedAttributeArray.Add("StartDateActual");
		NotCheckedAttributeArray.Add("ActualCompletionDate");
		
		NotCheckedAttributeArray.Add("LaborCosts.Team");
		
	EndIf;
	
	If ValueIsFilled(StartDate) And ValueIsFilled(CompletedOn)
		And StartDate > CompletedOn Then
		
		ErrorText = NStr("vi = 'Ngày hoàn thành theo kế hoạch %CompletedOn% phải không ít hơn ngày bắt đầu dự kiến %StartDate%';
						|ru = 'Плановая дата завершения работ %CompletedOn% должна быть не меньше плановой даты начала %StartDate%';
						|en = 'Planned end date %CompletedOn% of repair activities must be on or after planned start date %StartDate%'; fa = 'Planned end date %CompletedOn% of repair activities must be on or after planned start date %StartDate%';
						|it = 'La data del termine lavori prevista %CompletedOn% non deve essere inferiore alla data di inizio %StartDate% prevista';
						|pl = 'Planowana data zakończenia prac %CompletedOn% powinna być nie mniejsza niż planowa data początku %StartDate%';
						|tr = 'Planlanan tamamlanma tarihi %CompletedOn% , planlanan başlangıç tarihi %StartDate% ''den az olmamalıdır.'");
		ErrorText = StrReplace(ErrorText, "%StartDate%", Format(StartDate, "DLF=DD"));
		ErrorText = StrReplace(ErrorText, "%CompletedOn%", Format(CompletedOn, "DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"CompletedOn",
			,
			Cancel);
		
	EndIf;
	
	If Status = Enums.RMOrderStatuses.Closed
		And ValueIsFilled(StartDateActual) And ValueIsFilled(ActualCompletionDate)
		And StartDateActual > ActualCompletionDate Then
		
		ErrorText = NStr("vi = 'Ngày hoàn thành thực tế %CompletedOn% phải không ít hơn ngày bắt đầu thực tế %StartDate%';
						|ru = 'Фактическая дата завершения работ %CompletedOn% должна быть не меньше фактической даты начала %StartDate%';
						|en = 'Actual work finish date %CompletedOn% must be on or after actual start date %StartDate%'; fa = 'Actual work finish date %CompletedOn% must be on or after actual start date %StartDate%';
						|it = 'La data del termine lavori effettiva %CompletedOn% non deve essere inferiore alla data di inizio %StartDate% effettiva';
						|pl = 'Faktyczna data zakończenia prac %CompletedOn% powinna być nie mniejsza niż fakyczna data początku %StartDate%';
						|tr = 'Gerçek tamamlanma tarihi %CompletedOn%, gerçek başlangıç tarihi %StartDate%''den az olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%StartDate%", Format(StartDateActual, "DLF=DD"));
		ErrorText = StrReplace(ErrorText, "%CompletedOn%", Format(ActualCompletionDate, "DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"ActualCompletionDate",
			,
			Cancel);
		
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "MaterialsAndWorks";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "MaterialsAndWorks";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	CheckFillingOfRepairs(Cancel);
	CheckCompletionOfMaterialsAndWorks(Cancel);
	CheckFillingOfWorkCenters(Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RMOrder),
												Cancel,
												NotCheckedAttributeArray);
	
	CheckParameters = Documents.RMOrder.ParametersForCheckingDocumentFillingByTypeOfActivity(ThisObject);
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, ConsumptionForActivity, CheckParameters, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in the document in accordance with the selection
//
Procedure FillInSelectionDocument(Val FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
EndProcedure

// Fills in the document based on a link to the reference list of operating objects
//
Procedure FillInDocumentBasedOnObjectOfOperation(Val Basis)
	
	RM.Clear();
	
	Query = New Query(
		"SELECT
		|	Assets.Ref AS Asset,
		|	Assets.Status AS Status,
		|	CASE
		|		WHEN Assets.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Assets.DeletionMark AS ThereAreErrorsRemoved,
		|	Assets.IsFolder AS ThereAreErrorsGroup,
		|	ISNULL(Nodes.RMBusinessUnit, Assets.RMBusinessUnit) AS Department
		|FROM
		|	Catalog.Assets AS Assets
		|		LEFT JOIN Catalog.SubAssets AS Nodes
		|		ON Nodes.Ref = &Ref
		|WHERE
		|	(Assets.Ref = &Ref
		|			OR Assets.Ref IN
		|				(SELECT
		|					Nodes.Owner
		|				FROM
		|					Catalog.SubAssets AS Nodes
		|				WHERE
		|					Nodes.Ref = &Ref))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nodes.Ref AS Node,
		|	Nodes.Status AS Status,
		|	CASE
		|		WHEN Nodes.Status = VALUE(Enum.AssetStatuses.InOperation)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	Nodes.DeletionMark AS ThereAreErrorsRemoved
		|FROM
		|	Catalog.SubAssets AS Nodes
		|WHERE
		|	CASE
		|			WHEN Nodes.Ref = &Ref
		|				THEN TRUE
		|			WHEN Nodes.Owner = &Ref
		|				THEN Nodes.Status = VALUE(Enum.AssetStatuses.InOperation)
		|						AND NOT Nodes.DeletionMark
		|			ELSE FALSE
		|		END");
	
	Query.SetParameter("Ref", Basis);
	
	ErrorTextGroup_ = NStr("vi = 'Mục danh mục ''''%1'''' là một nhóm. Nhập trên cơ sở nhóm danh mục bị cấm.';
							|ru = 'Элемент справочника ""%1"" является группой. Ввод на основании групп справочника запрещен.';
							|en = '""%1"" is a group. Cannot generate documents from a group.'; fa = '""%1"" is a group. Cannot generate documents from a group.';
							|it = 'L''elemento di riferimento ""%1"" è un gruppo. L''immissione sulla base di gruppi di directory è proibita.';
							|pl = 'Element  katalogu ""%1"" jest grupa. Wprowadzenie na podstawie grup katalogu jest zabronione.';
							|tr = 'Dizin öğesi ""%1"" bir gruptur. Dizin gruplarına dayalı giriş yasaktır.'");
	ErrorTextDeleted = NStr("vi = '%1 ""%2"" được đánh dấu để xóa. Nhập dựa trên một mục thư mục được đánh dấu để xóa bị cấm.';
							|ru = '%1 ""%2"" помечен на удаление. Ввод на основании помеченного на удаление элемента справочника запрещен.';
							|en = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.'; fa = '%1 ""%2"" is marked for deletion. Cannot generate documents from items that have been marked for deletion.';
							|it = '%1 ""%2"" è stato selezionato per l''eliminazione. L''inserimento sulla base dell''elemento della directory contrassegnato per l''eliminazione è proibita.';
							|pl = '%1 ""%2"" zaznaczono do usunięcia. Wprowadzenie na podstawie zaznaczonego do usunięcia elementu katalogu jest zabronione.';
							|tr = '%1 ""%2"" silinmek üzere işaretlendi. Silinmek üzere işaretlenmiş bir dizin öğesi temelinde giriş yasaktır.'");
	ErrorTextStatus = NStr("vi = '%1 ""%2"" ở trạng thái ""%3"". Nhập trên cơ sở chỉ được phép trong trạng thái ""Đang sử dụng"".';
							|ru = '%1 ""%2"" находится в статусе ""%3"". Ввод на основании разрешен только в статусе ""В эксплуатации"".';
							|en = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".'; fa = '%1 ""%2"" in ""%3"" status. To generate a document, change its status to ""Operating"".';
							|it = '%1 ""%2"" si trova nello stato ""%3"". L''immissione in base alla causale è permessa solo nello stato ""In uso"".';
							|pl = '%1 ""%2"" ma status  ""%3"". Wprowadzenie na podstawie jest dozwolony tylko ze statusem ""W eksploatacji"".';
							|tr = '%1 ""%2"" ""%3"" durumundadır. Temelde girişe yalnızca "" İşlemde"" durumunda izin verilir.'");
	
	Package = Query.ExecuteBatch();
	If Not Package[0].IsEmpty() Then
		
		Selection = Package[0].Select();
		Selection.Next();
		
		If Selection.ThereAreErrorsGroup Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextGroup_,
				Selection.Asset);
			Raise ErrorText;
		ElsIf Selection.ThereAreErrorsRemoved Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextDeleted,
				NStr("vi = 'tài sản đang vận hành';
					|ru = 'Объект эксплуатации';
					|en = 'Asset'; fa = 'دارایی';
					|it = 'Oggetto di esercizio';
					|pl = 'Obiekt eksploatacji';
					|tr = 'Varlık'"),
				Selection.Asset);
			Raise ErrorText;
		ElsIf Selection.ThereAreErrorsStatus Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextStatus,
				NStr("vi = 'tài sản đang vận hành';
					|ru = 'Объект эксплуатации';
					|en = 'Asset'; fa = 'دارایی';
					|it = 'Oggetto di esercizio';
					|pl = 'Obiekt eksploatacji';
					|tr = 'Varlık'"),
				Selection.Asset,
				Selection.Status);
			Raise ErrorText;
		EndIf;
		
		Asset = Selection.Asset;
		Department = Selection.Department;
		
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		Selection = Package[1].Select();
		While Selection.Next() Do
			If Selection.ThereAreErrorsRemoved Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextDeleted,
					NStr("vi = 'Các chi tiết máy tài sản đang vận hành';
						|ru = 'Узел объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodo dell''oggetto di esercizio';
						|pl = 'Węzeł obiektu eksploatacji';
						|tr = 'Alt varlık'"),
					Selection.Node);
				Raise ErrorText;
			ElsIf Selection.ThereAreErrorsStatus Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextStatus,
					NStr("vi = 'Các chi tiết máy tài sản đang vận hành';
						|ru = 'Узел объекта эксплуатации';
						|en = 'Sub-asset'; fa = 'زیردارایی';
						|it = 'Nodo dell''oggetto di esercizio';
						|pl = 'Węzeł obiektu eksploatacji';
						|tr = 'Alt varlık'"),
					Selection.Node,
					Selection.Status);
				Raise ErrorText;
			EndIf;
			ThisObject.RM.Add().Node = Selection.Node;
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the document based on the registered defect
//
Procedure FillInDocumentOnBasisOfDefectRegistration(Val Basis)
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.DefectStatuses.Registered);
	ArrayOfValidStatuses.Add(Enums.DefectStatuses.RemovalIsDeferred);
	ArrayOfValidStatuses.Add(Enums.DefectStatuses.Recognized);
	
	Query = New Query(
		"SELECT
		|	RMRequest.Asset AS Asset,
		|	RMRequest.Asset.RMBusinessUnit AS Department,
		|	RMRequest.Decision AS TechnicalSolution,
		|	RMRequest.Ref AS Defect,
		|	NOT RMRequest.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN RMRequest.Status IN (&ArrayOfValidStatuses)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	RMRequest.Status AS DocumentStatus,
		|	RMRequest.RMOrderPlacingRequired AS RMOrderPlacingRequired
		|FROM
		|	Document.RMRequest AS RMRequest
		|WHERE
		|	RMRequest.Ref = &Basis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nodes.Node AS Node
		|FROM
		|	Document.RMRequest.DefectiveSubAssets AS Nodes
		|WHERE
		|	Nodes.Ref = &Basis
		|
		|ORDER BY
		|	Nodes.LineNumber");
	
	Query.SetParameter("ArrayOfValidStatuses", ArrayOfValidStatuses);
	Query.SetParameter("Basis", Basis);
	
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		
		Table = Package[0].Unload();
		Attributes = Table[0];
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			Attributes.Defect,
			Attributes.DocumentStatus,
			Attributes.ThereAreErrorsPosted,
			Attributes.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		If Not Attributes.RMOrderPlacingRequired Then
			ErrorText = NStr("vi = 'Đối với chứng từ %Document% đã chỉ ra phương pháp khắc phục ""Khắc phục tại chỗ"".
			|Chỉ cho phép nhập trên cơ sở đối với phương pháp khắc phục ""Cần sửa chữa"".';
			|ru = 'Для документа %Document% указан способ устранения ""Устраняется на месте"".
			|Ввод на основании разрешен только для способа устранения ""Требуется ремонт"".';
			|en = 'The ""Eliminated on site"" elimination method is specified for the %Document% document.
			|Input on basis is only allowed for the ""R&M is required"" elimination method.'; fa = 'The ""Eliminated on site"" elimination method is specified for the %Document% document.
			|Input on basis is only allowed for the ""R&M is required"" elimination method.';
			|it = 'Per il documento %Document% è indicata la modalità di eliminazione ""Viene eliminato sul posto"".
			|L''immissione in base alla causale è consentito solo per modalità di eliminazione ""È richiesta manutenzione"".';
			|pl = 'Dla dokumentu %Document% wskazano sposób usunięcia ""Устраняется на месте"".
			|Wprowadzenie na podstawie jest dozwolone tylko dla sposobu usunięcia ""Требуется ремонт"".';
			|tr = '%Document% belgesi için ""Sahada onarım"" iyileştirme yöntemi belirtilmiştir. 
			| Temelde girişe yalnızca ""Onarım gerekli"" iyileştirme yöntemi için izin verilir.'");
			ErrorText = StrReplace(ErrorText, "%Document%", Basis);
			Raise ErrorText;
		EndIf;
		
		FillPropertyValues(ThisObject, Attributes, "Asset, TechnicalSolution, Department");
		RemovedDefects.Load(Table);
		
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		RM.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

// Initializes the repair task
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Date = CurrentSessionDate();
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Author = Users.CurrentUser();
	
	ThisIsWorksConsumptionOrder = True;
	
	If Not ValueIsFilled(NameOfWork) Then
		NameOfWork = NStr("vi = 'Sửa chữa';
							|ru = 'Ремонт';
							|en = 'R&M'; fa = 'تعمیر و نگهداری';
							|it = 'Manutenzione';
							|pl = 'Naprawa';
							|tr = 'Bakım-onarım'");
	EndIf;
	
	If Not ValueIsFilled(StartDate) Then
		StartDate = Date;
	EndIf;
	
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(MaterialsAndWorks);
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
EndProcedure

// Fills in row keys for the specified table part
//
Procedure SetKeysInRowsOfTablePart(TabularSection, KeyName, CurMaximumKey)
	
	StringsWithoutKey = TabularSection.FindRows(New Structure(KeyName, 0));
	If StringsWithoutKey.Count() > 0 Then
		
		For Each LineProducts_ In StringsWithoutKey Do
			
			CurMaximumKey = CurMaximumKey + 1;
			LineProducts_[KeyName] = CurMaximumKey;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Checks whether the table part "Repairs" is filled in correctly"
//
Procedure CheckFillingOfRepairs(Cancel) 
	
	Query = New Query(
		"SELECT
		|	CAST(TabularSectionData.LineNumber AS NUMBER) AS LineNumber,
		|	CAST(TabularSectionData.Node AS Catalog.SubAssets) AS Node,
		|	CAST(TabularSectionData.RMType AS Catalog.RMTypes) AS RMType
		|INTO TabularSectionData
		|FROM
		|	&TabularSectionData AS TabularSectionData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TabularSectionData1.LineNumber AS LineNumber
		|FROM
		|	TabularSectionData AS TabularSectionData1
		|		INNER JOIN TabularSectionData AS TabularSectionData2
		|		ON TabularSectionData1.Node = TabularSectionData2.Node
		|			AND TabularSectionData1.RMType = TabularSectionData2.RMType
		|			AND TabularSectionData1.LineNumber <> TabularSectionData2.LineNumber");
	
	TableOfRepairs = ThisObject.RM.Unload();
	If Not GetFunctionalOption("UseSubAssets") Then
		TableOfRepairs.FillValues(Catalogs.SubAssets.EmptyRef(), "Node");
	EndIf;
	
	Query.SetParameter("TabularSectionData", TableOfRepairs);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	ErrorTemplate = NStr("vi = 'Sửa chữa ""%RMType%"" cho ""%ObjectOrNode%"" trong dòng %LineNumber% được lặp lại trong các hàng khác của phần bảng';
						|ru = 'Ремонт ""%RMType%"" для ""%ObjectOrNode%"" в строке %LineNumber% повторяется в других строках табличной части';
						|en = 'R&M activity ""%RMType%"" of ""%ObjectOrNode%"" in row %LineNumber% is duplicated in other rows'; fa = 'R&M activity ""%RMType%"" of ""%ObjectOrNode%"" in row %LineNumber% is duplicated in other rows';
						|it = 'La manutenzione ""%RMType%"" per ""%ObjectOrNode%"" nella riga %LineNumber% viene ripetuta nelle altre righe della parte tabulare';
						|pl = 'Remont ""%RMType%"" dla ""%ObjectOrNode%"" w wierszu %LineNumber% jest powtarzany w innych wierszach części tabelarycznej';
						|tr = '%LineNumber% satırındaki ""%ObjectOrNode%"" için ""%RMType%"" onarımı tablo bölümünün diğer satırlarında tekrarlanıyor'");
	
	While Selection.Next() Do
		
		RepairLine = TableOfRepairs[Selection.LineNumber - 1];
		ErrorText = StrReplace(ErrorTemplate, "%RMType%", ?(ValueIsFilled(RepairLine.RMType), RepairLine.RMType, NStr("vi = '<sửa chữa ngoài kế hoạch>';
																														|ru = '<произвольный ремонт>';
																														|en = '<any R&M>'; fa = '<any R&M>';
																														|it = '<manutenzione arbitraria>';
																														|pl = '<dowolny remont>';
																														|tr = '<keyfi onarım>'")));
		ErrorText = StrReplace(ErrorText, "%ObjectOrNode%", ?(ValueIsFilled(RepairLine.Node), RepairLine.Node, ThisObject.Asset));
		ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("RM", Selection.LineNumber, "LineNumber"),,
			Cancel);
		
	EndDo;
	
EndProcedure

// Checks whether the table part "Materials and works" is filled in correctly"
//
Procedure CheckCompletionOfMaterialsAndWorks(Cancel)
	
	EmbeddingParameters = Documents.RMOrder.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
	
	TextTemplate1 = NStr("vi = 'Chưa điền cột ""Kho bãi"" tại dòng %LineNumber% của danh sách ""Nguyên vật liệu và công việc""';
						|ru = 'Не заполнена колонка ""Склад"" в строке %LineNumber% списка ""Материалы и работы""';
						|en = 'The ""Warehouse"" column in line %LineNumber% of the ""Materials and works"" list is not filled in'; fa = 'The ""Warehouse"" column in line %LineNumber% of the ""Materials and works"" list is not filled in';
						|it = 'Non è compilata la colonna ""Magazzino"" nella riga %LineNumber% dell''elenco ""Materiali e lavori""';
						|pl = 'Nie wypełniono kolumny ""Magazyn"" w wierszu %LineNumber% listy ""Materiały i prace""';
						|tr = '""Malzemeler ve İşler"" listesinin %LineNumber% satırında ""Ambar"" sütunu doldurulmadı'");
	
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.WarehouseIsRequired And ErrorString.WarehouseIsNotFull Then
			
			ErrorText   = StrReplace(TextTemplate1, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("MaterialsAndWorks", ErrorString.LineNumber, "Warehouse");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks whether the "Work centers" table part of the passed document object is filled in correctly.
//
Procedure CheckFillingOfWorkCenters(Cancel)
	
	Query = New Query(
		"SELECT
		|	CAST(TabularSectionData.LineNumber AS NUMBER) AS LineNumber,
		|	TabularSectionData.WorkCenter AS WorkCenter,
		|	CAST(TabularSectionData.StartDate AS DATE) AS StartDate,
		|	CAST(TabularSectionData.CompletedOn AS DATE) AS CompletedOn
		|INTO TabularSectionData
		|FROM
		|	&TabularSectionData AS TabularSectionData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TabularSectionData1.LineNumber AS LineNumber
		|FROM
		|	TabularSectionData AS TabularSectionData1
		|		INNER JOIN TabularSectionData AS TabularSectionData2
		|		ON TabularSectionData1.WorkCenter = TabularSectionData2.WorkCenter
		|			AND TabularSectionData1.LineNumber <> TabularSectionData2.LineNumber
		|			AND (TabularSectionData1.StartDate <= TabularSectionData2.StartDate
		|					AND TabularSectionData1.CompletedOn > TabularSectionData2.StartDate
		|				OR TabularSectionData1.StartDate < TabularSectionData2.CompletedOn
		|					AND TabularSectionData1.CompletedOn >= TabularSectionData2.CompletedOn)");
	
	Query.SetParameter("TabularSectionData", ThisObject.WorkCenters.Unload());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	ErrorTemplate = NStr("vi = 'Khoảng dừng Nguồn lực sản xuất ""%RC%"" trong dòng %LineNumber% giao với các dòng khác của phần bảng';
						|ru = 'Интервал остановки рабочего центра ""%RC%"" в строке %LineNumber% пересекается с другими строками табличной части';
						|en = 'Work center ""%RC%"" idle time interval in row %LineNumber% overlaps with other intervals in the table'; fa = 'Work center ""%RC%"" idle time interval in row %LineNumber% overlaps with other intervals in the table';
						|it = 'L''intervallo del fermo del centro di lavoro ""%RC%"" nella riga %LineNumber% si sovrappone alle altre righe della parte tabulare';
						|pl = 'Interwał zatrzymania centrum pracy ""%RC%"" w wierszu %LineNumber% przecina się z innymi wierszami części tabelarycznej';
						|tr = '%LineNumber% satırındaki çalışma merkezi durma aralığı ""%RC%"" tablo bölümünün diğer satırlarıyla örtüşüyor'");
	
	While Selection.Next() Do
		
		String = ThisObject.WorkCenters[Selection.LineNumber - 1];
		ErrorText = StrReplace(ErrorTemplate, "%RC%", String.WorkCenter);
		ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("WorkCenters", Selection.LineNumber, "StartDate"),,
			Cancel);
		
	EndDo;
	
EndProcedure

Procedure PerformOrderControlAfterConducting(Cancel)

	If Status = Enums.RMOrderStatuses.Closed Then
		Array = CommonClientServer.ValueInArray(Ref);
		AdditionalParameters = New Structure("OrderFulfillmentControl", True);
		
		Query = Documents.RMOrder.GenerateVerificationRequestWhenStatusChanges(Array, "Closed", AdditionalParameters);
		
		Result = Query.Execute();
		
		SampleShipment = Result.Select();
		
		MessageTemplate = NStr("vi = 'Không thể đặt chứng từ %Document% thành trạng thái ""%Status%"", bởi vì đơn hàng chưa hoàn thành';
								|ru = 'У документа %Document% не может быть установлен статус ""%Status%"", т.к. заказ выполен не полностью';
								|en = 'The %Document% document cannot have the ""%Status%"" status as the order was fulfilled incompletely'; fa = 'The %Document% document cannot have the ""%Status%"" status as the order was fulfilled incompletely';
								|it = 'Per il documento %Document% non può essere impostato lo stato ""%Status%"" perché l''ordine non è completamente eseguito';
								|pl = 'Dla dokumentu %Document% nie może być ustawiony status ""%Status%"", ponieważ zamówienie jest wykonane nie w całości';
								|tr = 'Sipariş tamamen yerine getirilmediği için %Document% belgesi ""%Status%"" olarak ayarlanamıyor'");
		
		While SampleShipment.Next() Do
			
			CheckPassed = Documents.RMOrder.CheckingBeforeChangingStatus(
									SampleShipment, 
									Status, 
									AdditionalParameters, 
									MessageTemplate); 
									
			If Not CheckPassed Then
				Cancel = True;
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion

#EndIf
#EndIf

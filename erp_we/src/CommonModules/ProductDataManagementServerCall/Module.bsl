////////////////////////////////////////////////////////////////////////////////
// NSI of production: Procedures of the subsystem of product data management
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Specifications

// Returns the specification of the product
//
// Parameters:
//  ProductData             - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters - See ProductDataManagementClientServer.BOMSelectionParameters
// 
// Returns:
//  Structure, Undefined - contains product specification data.
//
Function ProductSpecification(ProductData, BOMSelectionParameters) Export
	
	SpecificationData = Undefined;
	
	BOMList = ProductDataManagement.BillsOfMaterial(ProductData, BOMSelectionParameters);
	
	For IndexOf = 0 To BOMList.UBound() Do
		
		If SpecificationData = Undefined And BOMList[IndexOf].SelectedAutomatically = True Then
			SpecificationData = BOMList[IndexOf];
			If Not ValueIsFilled(ProductData.CurrentSpecification) Then
				Break;
			EndIf;
		EndIf;
		
		If BOMList[IndexOf].BillOfMaterials = ProductData.CurrentSpecification Then
			SpecificationData = BOMList[IndexOf];
			Break;
		EndIf;
		
	EndDo;
	
	Return SpecificationData;
	
EndFunction

// Copies of the specification and stages
//
// Parameters:
//  Source	- CatalogRef.BillsOfMaterials - the specification to copy.
//
// Returns:
//   CatalogRef.BillsOfMaterials   - a copy of the specification.
//
Function CopyResourceSpecification(Source) Export
	
	BeginTransaction();
	Try
		
		RefToNew = Catalogs.BillsOfMaterials.GetRef();
		
		Object = Source.Copy();
		Object.Description = Object.Description + " " + NStr("vi = '(bản sao)';
															|ru = '(копия)';
															|en = '(copy)'; fa = '(copy)';
															|it = '(copia)';
															|pl = '(copy)';
															|tr = '(kopya)'");
		
		If Not FillInStepsAccordingToResourceSpecification(Object, Source, RefToNew) Then
			
			RollbackTransaction();
			Return Undefined;
			
		EndIf;
		
		ProductDataManagement.UpdateObjectLinkKeys(Object);
		ProductDataManagement.CopyValuesOfSpecificationAssignmentParameters(Source, RefToNew);
		Object.SetNewObjectRef(RefToNew);
		Object.Write();
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		MessageText = StrTemplate(NStr("vi = 'Không thể sao chép bảng kê chi tiết do nguyên nhân: %1';
										|ru = 'Не удалось скопировать спецификацию по причине: %1';
										|en = 'Cannot copy the bill of materials due to: %1'; fa = 'Cannot copy the bill of materials due to: %1';
										|it = 'Non è stato possibile copiare la specifica a causa di: %1';
										|pl = 'Nie udało się skopiować specyfikacji z powodu: %1';
										|tr = 'Ürün reçetesinin kopyalanamama nedeni: %1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(MessageText, Source); 
		
		WriteLogEvent(ProductionServer.CopySpecificationEvent(), 
			EventLogLevel.Error,,Source, MessageText);
		
		Return Undefined;
		
	EndTry;
	
	Return Object.Ref;
	
EndFunction

// Reverse kitting filling data based on kitting.
// 
// Parameters:
//  Source - CatalogRef.BillsOfMaterials
// 
// Returns:
//  Structure - fill-in data
Function FillingReverseKittingDataBasedOnKITTING(Source) Export
	
	Result = New Structure("ProductionProcessType", Enums.ProductionProcessTypes.Disassembly);
	
	If ValueIsFilled(Source) Then
		
		Object = Source.GetObject();
		
		Result.Insert("Description", StrTemplate(NStr("vi = '%1 (Tách bộ)';
														|ru = '%1 (Разборка)';
														|en = '%1 (Disassembly)'; fa = '%1 (Disassembly)';
														|it = '%1 (Disassembly)';
														|pl = '%1 (Disassembly)';
														|tr = '%1 (Demontaj)'"), Object.Description));
		Result.Insert("Parent", Object.Parent);
		
		Result.Insert("Products", Object.MainProductProducts);
		Result.Insert("Characteristic", Object.MainProductCharacteristic);
		Result.Insert("NumberOfPackages", Object.MainProductNumberOfPackages);
		Result.Insert("Package", Object.MainProductPackage);
		
		If Object.MaterialsAndServices.Count() > 0 Then
			
			FilterConnectionKey = New Structure("ConnectionKey");
			
			Result.Insert("ManufacturedProducts", Object.MaterialsAndServices.Unload());
			
			For Each String In Result.ManufacturedProducts Do
				
				NewCommunicationKey_ = New UUID();
				FilterConnectionKey.ConnectionKey = String.ConnectionKey;
				
				String.ConnectionKey              = NewCommunicationKey_;
				String.Stage                   = Undefined;
				String.StageEditing     = Undefined;
				String.Operation               = Undefined;
				String.OperationEdit = Undefined;
				
				For Each TSName In StrSplit("SelectionByProperties,PropertyMapping", ",") Do
					For Each String In Object[TSName].Unload(FilterConnectionKey) Do
						Table = Undefined; // ValueTable
						If Not Result.Property(TSName, Table) Then
							Table = Object[TSName].UnloadColumns();
							Result.Insert(TSName, Table);
						EndIf;
						NewRow = Table.Add();
						FillPropertyValues(NewRow, String);
						NewRow.ConnectionKey = NewCommunicationKey_;
					EndDo;
				EndDo;
				
			EndDo;
			
		EndIf;
		
		For Each KeyAndValue In Result Do
			If TypeOf(KeyAndValue.Value) = Type("ValueTable") Then
				Result.Insert(KeyAndValue.Key, PutToTempStorage(KeyAndValue.Value));
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RouteSheets

// Checks that the route map can be assigned as the primary one
//
// Parameters:
//  Ref			- CatalogRef.RouteSheets - link to the route map
//  ErrorStructure	- Structure - contains the verification result: 
//								1. Text errors: the reason why the Route Sheet cannot be the main one.
//
// Returns:
//   Boolean   - True, if you can assign the main one.
//
Function YouCanAssignRouteMapToMainOne(Ref, ErrorStructure) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	RouteSheets.Status AS Status,
	|	COUNT(RouteSheetsManufacturedProducts.LineNumber) AS NumberOfProducts
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|		LEFT JOIN Catalog.RouteSheets.ManufacturedProducts AS RouteSheetsManufacturedProducts
	|		ON (RouteSheetsManufacturedProducts.Ref = RouteSheets.Ref)
	|WHERE
	|	RouteSheets.Ref = &Ref
	|
	|GROUP BY
	|	RouteSheets.Ref,
	|	RouteSheets.Status";
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Selection.Next();
	
	If Selection.Status <> PredefinedValue("Enum.StatusesOfRouteSheets.Valid") Then
		ErrorStructure.Insert("ErrorText", NStr("vi = 'Cái chính chỉ có thể là một bản đồ lộ trình hợp lệ.';
												|ru = 'Основной может быть только действующая маршрутная карта.';
												|en = 'Only a valid route sheet can be assigned as the main one.'; fa = 'Only a valid route sheet can be assigned as the main one.';
												|it = 'Come principale ci può essere solo una scheda di lavorazione attiva.';
												|pl = 'Podstawą może być tylko ważna karta technologiczna.';
												|tr = 'Sadece mevcut Rota temel olabilir.'"));
		Return False;
	ElsIf Selection.NumberOfProducts = 0 Then
		ErrorStructure.Insert("ErrorText", NStr("vi = 'Bản sơ đồ quy trình phải chứa các sản phẩm đầu ra.';
												|ru = 'В маршрутной карте должны быть выходные изделия.';
												|en = 'The route sheet must contain finished products.'; fa = 'The route sheet must contain finished products.';
												|it = 'Nella scheda di lavorazione devono esserci i prodotti di output.';
												|pl = 'Karta technologiczna powinna zawierać wychodzące produkty.';
												|tr = 'Rotada üretilen nihai ürünler olmalıdır.'"));
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Assigns the main route map for the specified product and division
//
// Parameters:
//  RecordProperties 		- Structure - contains the values of the record's properties
//  URL - String - navigation link to the modified record.
//  ErrorStructure	- Structure - contains the result of the check
//
// Returns:
//   Boolean   - True if the route map is assigned to the main one.
//
Function SetAsMainOperationsSheet(RecordProperties, URL = Undefined, ErrorStructure = Undefined) Export
	
	ErrorStructure = New Structure;
	
	// Let's check that the route map can be assigned to the main one
	If Not YouCanAssignRouteMapToMainOne(RecordProperties.RouteSheet, ErrorStructure) Then
		Return False;
	EndIf;
	
	RouteMapDivision = Common.ObjectAttributeValue(RecordProperties.RouteSheet, "Department");
	
	// Write down the data
	Record = InformationRegisters.MainRouteSheets.CreateRecordManager();
	FillPropertyValues(Record, RecordProperties);
	Record.Department = RouteMapDivision;
	
	Try
		Record.Write();
	Except
		ErrorDescription = ErrorDescription();
		Return False;
	EndTry; 
	
	CurRecordStructure = New Structure;
	CurRecordStructure.Insert("Department",   Record.Department);
	CurRecordStructure.Insert("Products",    Record.Products);
	CurRecordStructure.Insert("Characteristic",  Record.Characteristic);
	CurRecordStructure.Insert("RouteSheet", Record.RouteSheet);
	
	RecordKey = InformationRegisters.MainRouteSheets.CreateRecordKey(CurRecordStructure);
	URL = GetURL(RecordKey);
	
	Return True;
	
EndFunction

// Gets the values of the route map details
// 
// Parameters:
// 	RouteSheet - CatalogRef.RouteSheets
// Returns:
// 	Structure - see the structurequisitovmarchrutecards
Function RouteCardDetailsValues(RouteSheet) Export
	
	Return Catalogs.RouteSheets.RouteCardDetailsValues(RouteSheet);
	
EndFunction

#EndRegion

#Region BOMsTree

// Gets the child line items of the tree spec
//
// Parameters:
//  Id	 - UUID	 - row ID
//  AddressInStorage	 - String					 - address of the specification tree in temporary storage.
// 
// Returns:
//   - Array - subordinate elements of the specification tree line.
//
Function TreeSpecificationsReadElements(Id, AddressInStorage) Export
	
	Return ProductDataManagement.TreeSpecificationsReadElements(Id, AddressInStorage);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure ResourceSpecificationsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.Property("GetProductBOM") And Parameters.Property("Products") Then
		
		StandardProcessing = False;
		ChoiceData = New ValueList;
		
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		FillPropertyValues(ProductData, Parameters);
		
		List = ProductDataManagement.ListOfSpecificationsByProduct(ProductData, Parameters);
		ChoiceData.LoadValues(List);
		
	EndIf; 
	
EndProcedure

Procedure ResourceSpecificationsFormReceiptProcessing(FormType, Parameters, SelectedForm, StandardProcessing) Export

	If FormType = "ChoiceForm" And Parameters.Property("GetProductBOM") And Parameters.Property("Products") Then
		SelectedForm = "ChoiceFormByItems";
		StandardProcessing = False;
	EndIf;

EndProcedure

Function SetStatusOfSpecifications(HighlightedLinks, StatusValue) Export

	NewStatus = Enums.BOMStatuses[StatusValue];
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	BillsOfMaterials.Ref,
	|	BillsOfMaterials.Description,
	|	BillsOfMaterials.DeletionMark
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	BillsOfMaterials.Status <> &NewStatus
	|	AND BillsOfMaterials.Ref IN(&HighlightedLinks)";
	
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("NewStatus",      NewStatus);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	
	If NewStatus = Enums.BOMStatuses.UnderDevelopment Then
		StorageAddress = PutToTempStorage(Undefined);
	EndIf;
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Bạn không thể thay đổi trạng thái của bảng kê chi tiết các nguồn lực sản xuất được đánh dấu để xóa là ""%1"".';
										|ru = 'Нельзя изменить статус помеченной на удаление спецификации ""%1"".';
										|en = 'Cannot change a status of the ""%1"" bill of materials marked for deletion.'; fa = 'Cannot change a status of the ""%1"" bill of materials marked for deletion.';
										|it = 'È proibito cambiare lo stato della specifica ""%1"" contrassegnata per l''eliminazione.';
										|pl = 'Nie można zmienić statusu oznaczonej do usunięcia specyfikacji ""%1"".';
										|tr = 'Silinmek üzere işaretlenen ""%1"" ürün reçetesinin durumu değiştirilemez.'"),
									Selection.Description);
									
			Common.MessageToUser(MessageText, Selection.Ref); 
			Continue;
		EndIf;
		
		CatObject = Selection.Ref.GetObject();
		
		BeginTransaction();
		
		Try
			
			If NewStatus = Enums.BOMStatuses.UnderDevelopment Then
				CheckParameters = New Structure("Object", Selection.Ref);
				Catalogs.BillsOfMaterials.CheckObjectUsage(CheckParameters, StorageAddress);
				ThereAreRefs = GetFromTempStorage(StorageAddress);
				If ThereAreRefs Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất ""%1"" được sử dụng. Đặt trạng thái ""Đang phát triển"" chỉ được phép ở dạng bảng kê chi tiết các nguồn lực sản xuất.';
												|ru = 'Спецификация ""%1"" используется. Установка статуса ""В разработке"" допускается только в форме спецификации.';
												|en = 'Bill of materials ""%1"" is used. It is allowed to set the ""Under development"" status only in the BOM form.'; fa = 'Bill of materials ""%1"" is used. It is allowed to set the ""Under development"" status only in the BOM form.';
												|it = 'La specifica ""%1"" è in uso. L''impostazione dello stato ""In elaborazione"" è disponibile solo nel form della specifica.';
												|pl = 'Specyfikacja ""%1"" jest używana. Instalacja statusu ""W trakcie projektowania"" jest dozwolona tylko w postaci specyfikacji.';
												|tr = '""%1"" ürün reçetesi kullanılmaktadır. ""Geliştirme aşamasında"" durumunun yapılandırılmasına sadece ürün reçetesi formunda izin verilmektedir.'"),
											CatObject.Description);
											
					Common.MessageToUser(MessageText, Selection.Ref); 
					RollbackTransaction();
					Continue;
				EndIf;
			ElsIf NewStatus = Enums.BOMStatuses.Closed_
					And Not ValueIsFilled(CatObject.ValidToDate) Then
				CatObject.ValidToDate = CurrentSessionDate();
			EndIf;
			
			CatObject.Status = NewStatus;
			CatObject.AdditionalProperties.Insert("ProhibitCalculationOfProductionDuration");
			If CatObject.CheckFilling() Then
				CatObject.Write();
				ProcessedItemsCount = ProcessedItemsCount + 1;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
	EndDo;
	
	InformationRegisters.JobsOfStandardProductionDurationCalculation.RunJob();
	
	Return ProcessedItemsCount;

EndFunction

Function FillInStepsAccordingToResourceSpecification(Receiver, Source, ReceiverLink_)

	Query = New Query(
	// 0
	"SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1
	|SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 2
	|SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 3
	|SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.LaborCosts AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 4
	|SELECT
	|	CatalogProductionStages.Ref AS Ref,
	|	CatalogProductionStages.StageNumber AS StageNumber,
	|	CatalogProductionStages.NextStageNo AS NextStageNo
	|FROM
	|	Catalog.ProductionStages AS CatalogProductionStages
	|WHERE
	|	CatalogProductionStages.Owner = &Source
	|	AND NOT CatalogProductionStages.DeletionMark
	|
	|ORDER BY
	|	StageNumber
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 5
	|SELECT
	|	CatalogManufacturingOperations.Ref AS Ref,
	|	CatalogManufacturingOperations.Owner AS Stage,
	|	CatalogManufacturingOperations.OperationNumber AS OperationNumber,
	|	CatalogManufacturingOperations.NextOperation AS NextOperation,
	|	CatalogManufacturingOperations.Id AS Id
	|FROM
	|	Catalog.ManufacturingOperations AS CatalogManufacturingOperations
	|WHERE
	|	CatalogManufacturingOperations.BillOfMaterials = &Source
	|	AND NOT CatalogManufacturingOperations.DeletionMark
	|
	|ORDER BY
	|	Stage,
	|	OperationNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 6
	|SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.IntermediateRelease AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 7
	|SELECT
	|	*
	|FROM
	|	Catalog.BillsOfMaterials.WorksToPerform AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Source
	|
	|ORDER BY
	|	TabularSection.LineNumber
	|");
	
	Query.SetParameter("Source", Source);
	
	Result = Query.ExecuteBatch();
	
	ExcludedAttributes = "Stage";
	ExcludedAttributes = "Stage,Operation";
	TabularSectionNames = Catalogs.BillsOfMaterials.TabularSectionNames();
	For Each TSName In TabularSectionNames Do
		Receiver[TSName].Clear();
		For Each String In Result[TabularSectionNames.Find(TSName)].Unload() Do
			FillPropertyValues(Receiver[TSName].Add(), String,, ExcludedAttributes);
		EndDo;
	EndDo;
	
	StepsTable = Result[4].Unload();
	TransactionTable = Result[5].Unload();
	TransactionTable.Indexes.Add("Stage");
	Receiver.IntermediateRelease.Load(Result[6].Unload());
	Receiver.WorksToPerform.Load(Result[7].Unload());
	For IndexStage = 0 To StepsTable.Count() - 1 Do
		
		StageString = StepsTable[IndexStage]; // CatalogObject.ProductionStages
		
		If IndexStage = 0
			Or ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable() Then
			
			StageObject = StageString.Ref.Copy();
			StageObject.Owner = ReceiverLink_;
			If ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable() Then
				StageObject.StageNumber = StageString.StageNumber;
				StageObject.NextStageNo = StageString.NextStageNo;
			Else
				StageObject.StageNumber = 1;
				StageObject.NextStageNo = 0;
			EndIf;
			
			StageObject.DataExchange.Load = True;
			
			Try
				
				StageObject.Write();
				
			Except
				
				MessageText = StrTemplate(NStr("vi = 'Không thể ghi lại công đoạn ""%1"" do nguyên nhân: %2';
												|ru = 'Не удалось записать этап ""%1"" по причине: %2';
												|en = 'Cannot save the ""%1"" stage due to: %2'; fa = 'Cannot save the ""%1"" stage due to: %2';
												|it = 'Non è stato possibile registrare la fase ""%1"" a causa di: %2';
												|pl = 'Nie udało się zapisać etapu ""%1"" z powodu: %2';
												|tr = '""%1"" aşamasının kaydedilememe nedeni: %2'"),
					StageObject.Description,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				Common.MessageToUser(MessageText, Source);
				
				WriteLogEvent(ProductionServer.CopySpecificationEvent(), 
					EventLogLevel.Error,,Source, MessageText);
				
				Return False;
				
			EndTry;
			
			NewStepRef = StageObject.Ref;
			
		Else
			
			NewStepRef = Catalogs.ProductionStages.EmptyRef();
			
		EndIf;
		
		ReplaceReferencesInCollection(Receiver.ManufacturedProducts,  "StageEditing", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.RecyclableWaste, "StageEditing", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.MaterialsAndServices, "StageEditing", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.MaterialsAndServices, "SourceOfSemiFinishedProduct", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.MaterialsAndServices, "PlanNotEarlierThan", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.LaborCosts,     "StageEditing", StageString.Ref, NewStepRef);
		
		If Receiver.MainProductStage = StageString.Ref Then
			Receiver.MainProductStage = NewStepRef;
		EndIf;
		ReplaceReferencesInCollection(Receiver.IntermediateRelease, "StageSender", StageString.Ref, NewStepRef);
		ReplaceReferencesInCollection(Receiver.IntermediateRelease, "RecipientStage", StageString.Ref, NewStepRef);
		
		ReplaceReferencesInCollection(Receiver.WorksToPerform, "Stage", StageString.Ref, NewStepRef);
		
		For Each LineOperation In TransactionTable.FindRows(New Structure("Stage", StageString.Ref)) Do // CatalogObject.ManufacturingOperations
			
			If ValueIsFilled(NewStepRef) Then
			
				OperationObject = LineOperation.Ref.Copy(); // CatalogObject.ManufacturingOperations
				OperationObject.Owner = NewStepRef;
				OperationObject.OperationNumber = LineOperation.OperationNumber;
				OperationObject.NextOperation = LineOperation.NextOperation;
				OperationObject.BillOfMaterials = ReceiverLink_;
				OperationObject.Id = LineOperation.Id;
				
				OperationObject.DataExchange.Load = True;
				
				Try
					
					OperationObject.Write();
					
				Except
					
					MessageText = StrTemplate(NStr("vi = 'Không thể ghi lại giao dịch ""%1"" do nguyên nhân: %2';
													|ru = 'Не удалось записать операцию ""%1"" по причине: %2';
													|en = 'Cannot save the ""%1"" operation due to: %2'; fa = 'Cannot save the ""%1"" operation due to: %2';
													|it = 'Non è stato possibile registrare l''operazione ""%1"" a causa di: %2';
													|pl = 'Nie udało się zapisać operacji ""%1"" z powodu: %2';
													|tr = '""%1"" işleminin kaydedilememe nedeni: %2'"),
						OperationObject.Description,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					
					Common.MessageToUser(MessageText, Source);
					
					WriteLogEvent(ProductionServer.CopySpecificationEvent(), 
						EventLogLevel.Error,,Source, MessageText);
					
					Return False;
					
				EndTry;
			
				NewLinkOfOperation = OperationObject.Ref;
			
			Else
				
				NewLinkOfOperation = Catalogs.ManufacturingOperations.EmptyRef();
				
			EndIf;
			
			ReplaceReferencesInCollection(Receiver.ManufacturedProducts,  "OperationEdit", LineOperation.Ref, NewLinkOfOperation);
			ReplaceReferencesInCollection(Receiver.RecyclableWaste, "OperationEdit", LineOperation.Ref, NewLinkOfOperation);
			ReplaceReferencesInCollection(Receiver.MaterialsAndServices, "OperationEdit", LineOperation.Ref, NewLinkOfOperation);
			ReplaceReferencesInCollection(Receiver.LaborCosts,     "OperationEdit", LineOperation.Ref, NewLinkOfOperation);
			ReplaceReferencesInCollection(Receiver.IntermediateRelease, "SenderOperation", LineOperation.Ref, NewLinkOfOperation);
			ReplaceReferencesInCollection(Receiver.IntermediateRelease, "OperationRecipient", LineOperation.Ref, NewLinkOfOperation);
			
		EndDo;
	EndDo;
	
	Return True;
	
EndFunction

Procedure ReplaceReferencesInCollection(Collection, FieldName, Ref, NewRef)
	
	Filter = New Structure(FieldName, Ref);
	
	FoundRows = Collection.FindRows(Filter);
	
	For Each FoundRow In FoundRows Do
		
		FoundRow[FieldName] = NewRef;
		
	EndDo;
	
EndProcedure

Function SetRouteMapStatus(HighlightedLinks, StatusValue) Export

	NewStatus = Enums.StatusesOfRouteSheets[StatusValue];
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	RouteSheets.Ref,
	|	RouteSheets.Description,
	|	RouteSheets.DeletionMark
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|WHERE
	|	RouteSheets.Status <> &NewStatus
	|	AND RouteSheets.Ref IN(&HighlightedLinks)";
	
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("NewStatus",      NewStatus);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	
	If NewStatus = Enums.StatusesOfRouteSheets.UnderDevelopment Then
		StorageAddress = PutToTempStorage(Undefined);
	EndIf;
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Bạn không thể thay đổi trạng thái của cờ được đánh dấu để xóa bản đồ tuyến đường ""%1"".';
										|ru = 'Нельзя изменить статус помеченной на удаление маршрутной карты ""%1"".';
										|en = 'Cannot change status of the ""%1"" route sheet because it is marked for deletion.'; fa = 'Cannot change status of the ""%1"" route sheet because it is marked for deletion.';
										|it = 'Non è possibile modificare lo stato della scheda di lavorazione ""%1"" contrassegnata per la cancellazione.';
										|pl = 'Nie można zmienić statusu oznaczonej do usunięcia karty technologicznej ""%1"".';
										|tr = 'Silinmek üzere işaretlenen ""%1"" rotanın durumu değiştirilemez.'"),
									Selection.Description);
									
			CommonClientServer.MessageToUser(MessageText, Selection.Ref); 
			Continue;
		EndIf;
		
		CatObject = Selection.Ref.GetObject();
		
		BeginTransaction();
		
		Try
			
			If NewStatus = Enums.StatusesOfRouteSheets.UnderDevelopment Then
				CheckParameters = New Structure("Object", Selection.Ref);
				Catalogs.RouteSheets.CheckObjectUsage(CheckParameters, StorageAddress);
				ThereAreRefs = GetFromTempStorage(StorageAddress);
				If ThereAreRefs Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Sơ đồ quy trình ""%1""đang được sử dụng. Đặt trạng thái ""Đang phát triển"" chỉ được phép ở dạng sơ đồ quy trình.';
												|ru = 'Маршрутная карта ""%1"" используется. Установка статуса ""В разработке"" допускается только в форме маршрутной карты.';
												|en = 'The ""%1"" route sheet is in use. To set ""Under development"" status, go to the route sheet form.'; fa = 'The ""%1"" route sheet is in use. To set ""Under development"" status, go to the route sheet form.';
												|it = 'La scheda di lavorazione ""%1"" è in uso. L''impostazione dello stato ""In elaborazione"" è disponibile solo nel form della scheda di lavorazione.';
												|pl = 'Karta technologiczna ""%1"" jest używana. Ustawić status ""W opracowaniu"" można tylko w formie karty technologicznej.';
												|tr = '""%1"" Rota kullanılmaktadır. ""Geliştirme aşamasında"" durumunun yapılandırılmasına sadece rota formunda izin verilmektedir.'"),
											CatObject.Description);
											
					CommonClientServer.MessageToUser(MessageText, Selection.Ref); 
					RollbackTransaction();
					Continue;
				EndIf;
			EndIf; 
			
			CatObject.Status = NewStatus;
			If CatObject.CheckFilling() Then
				CatObject.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Continue;
		EndTry;
		ProcessedItemsCount = ProcessedItemsCount + 1;
		
	EndDo;
	
	Return ProcessedItemsCount;

EndFunction

Procedure RouteMapsProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.Property("SelectValidRouteSheets") Then
		
		StandardProcessing = False;
		
		If Parameters.Property("Filter") And Parameters.Filter.Property("Department") Then
			Department = Parameters.Filter.Department;
		Else
			Department = Catalogs.BusinessStructure.EmptyRef();
		EndIf; 
		If Parameters.Property("Filter") And Parameters.Filter.Property("ProductionStart") Then
			ProductionStart = Parameters.Filter.ProductionStart;
		Else
			ProductionStart = '000101010000';
		EndIf; 
		
		ChoiceData =  ProductDataManagement.CurrentRouteMapsOfDivision(
								Department, 
								ProductionStart, 
								Parameters.SearchString)
	EndIf; 
	
	If Parameters.Property("DisableSelection") Then
		
		StandardProcessing = False;
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	RouteSheets.Ref AS RouteSheet,
		|	RouteSheets.Presentation AS RouteSheetPresentation
		|FROM
		|	Catalog.RouteSheets AS RouteSheets
		|WHERE
		|	RouteSheets.Ref <> &Ref
		|	AND &SearchString
		|	AND &FIlterRow
		|ORDER BY
		|	RouteSheetPresentation";
		
		SearchString = "";
		If Parameters.SearchString <> Undefined Then
			Query.SetParameter("Text",  "%" + TrimAll(Parameters.SearchString) + "%");
			SearchString = "AND RouteSheets.Description LIKE &Text";
		EndIf;
		Query.Text = StrReplace(Query.Text, "AND &SearchString", SearchString);
		
		FIlterRow = "";
		If Parameters.Property("Filter") Then
			For Each FilterElement In Parameters.Filter Do
				FIlterRow = FIlterRow + " And " + FilterElement.Key + " = &" + FilterElement.Key;
				Query.SetParameter(FilterElement.Key, FilterElement.Value);
			EndDo; 
		EndIf;
		Query.Text = StrReplace(Query.Text, "AND &FIlterRow", FIlterRow);
		
		Query.SetParameter("Ref", Parameters.DisableSelection);
		
		Selection = Query.Execute().Select();
		
		ChoiceData = New ValueList;
		
		While Selection.Next() Do
			ChoiceData.Add(Selection.RouteSheet, Selection.RouteSheetPresentation);
		EndDo;

	EndIf; 
	
EndProcedure

Procedure TechnologicalOperationsProcessingOfObtainingForm(FormType, Parameters, SelectedForm, StandardProcessing) Export

	If FormType = "ObjectForm" Then
		
		If Parameters.Property("FillingValues") Then
			
			If TypeOf(Parameters.FillingValues) = Type("Structure") And Parameters.FillingValues.Property("ContainsNestedRoute") And Parameters.FillingValues.ContainsNestedRoute Then
				
				SelectedForm = "NestedRouteForm";
				StandardProcessing = False;
				
			EndIf;
			
		ElsIf Parameters.Property("CopyingValue") Then
			
			ContainsNestedRoute = Common.ObjectAttributeValue(Parameters.CopyingValue, "ContainsNestedRoute");
			
			If ContainsNestedRoute Then
				
				SelectedForm = "NestedRouteForm";
				StandardProcessing = False;
				
			EndIf;
			
		ElsIf Parameters.Property("Key") Then
			
			ContainsNestedRoute = Common.ObjectAttributeValue(Parameters.Key, "ContainsNestedRoute");
			
			If ContainsNestedRoute Then
				
				SelectedForm = "NestedRouteForm";
				StandardProcessing = False;
				
			EndIf;
			
		EndIf;
		
	EndIf; 
	
EndProcedure

#EndRegion
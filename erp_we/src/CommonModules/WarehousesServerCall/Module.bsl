
#Region Public

#Region ProcessingWarehouseTasksInForms

// Changes the status of documents "selection (placement) of goods" to " Completed without errors"
//
//	Parameters:
//		DocumentsArray - Array - array of links to documents that need to change their status
//		AssignAssignee - Boolean - when setting the status, record the task performer
//		Performer - CatalogRef.Users - if Assign Executor = TRUE, then
//					the installed executor is passed in this parameter
//	Returns:
//		Array - array of links to documents that have changed the status.
//
Function MarkCompletionOfTasksWithoutErrors(Val DocumentsArray, AssignAssignee, Performer = Undefined) Export	
	
	ArrayOfChangedDocuments = New Array;
	IndexOf = DocumentsArray.Count();
	
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		ArrRow = DocumentsArray[IndexOf];
		
		DocumentAttributes = Common.ObjectAttributesValues(ArrRow, "Status, Posted");
		If Not DocumentAttributes.Posted Then 
			MessageText = NStr("vi = 'Không thay đổi trạng thái chứng từ %Document%: có thể thay đổi trạng thái bằng bộ xử lý theo nhóm chỉ đối với các chứng từ đã kết chuyển.';
								|ru = 'Статус документа %Document% не изменен: групповой обработкой можно изменять статусы только для проведенных документов.';
								|en = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.'; fa = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.';
								|it = 'Lo stato del documento %Document% non è modificato: tramite elaborazione collettiva è possibile modificare lo stato solo per i documenti registrati.';
								|pl = 'Status dokumentu %Document% nie jest zmieniony: przetwarzaniem grupowym można zmieniać statusy tylko dla zatwierdzonych dokumentów.';
								|tr = 'Belge durumu %Document% değiştirilmedi: Grup işleme, yalnızca kaydedilen belgelerin durumlarını değiştirebilir.'");
			
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			
			CommonClientServer.MessageToUser(MessageText);
			
			DocumentsArray.Delete(IndexOf);
		ElsIf DocumentAttributes.Status <> Enums.StatusesOfGoodsPickingPlacement.Prepared2
			And DocumentAttributes.Status <> Enums.StatusesOfGoodsPickingPlacement.InProgress Then
			
			MessageText = NStr("vi = 'Không thay đổi trạng thái chứng từ %Document%: có thể đặt trạng thái %CompletedWithoutErrors% bằng bộ xử lý theo nhóm chỉ đối với các chứng từ có trạng thái %Prepared2% hoặc %InProgress%.';
								|ru = 'Статус документа %Document% не изменен: групповой обработкой статус %CompletedWithoutErrors% можно установить только для документов в статусе %Prepared2% или %InProgress%.';
								|en = 'The %Document% document status is not changed: you can set the %CompletedWithoutErrors% status by group processing only for documents in the %Prepared2% or %InProgress% status.'; fa = 'The %Document% document status is not changed: you can set the %CompletedWithoutErrors% status by group processing only for documents in the %Prepared2% or %InProgress% status.';
								|it = 'Lo stato del documento %Document% non è modificato: lo stato %CompletedWithoutErrors% può essere impostato solo per i documenti con lo stato %Prepared2% o %InProgress% tramite l''elaborazione a blocchi.';
								|pl = 'Status dokumentu %Document% nie został zmieniony: grupowym traktowaniem status %CompletedWithoutErrors% można ustawić tylko dla dokumentów o statusie %Prepared2% lub %InProgress%.';
								|tr = '%Document% belge durumu değiştirilmemiştir: %CompletedWithoutErrors% durumu grup işleme tarafından yalnızca %Prepared2% veya %InProgress% durumundaki belgeler için ayarlanabilir.'");
			
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			MessageText = StrReplace(MessageText, "%InProgress%", Enums.StatusesOfGoodsPickingPlacement.InProgress);
			MessageText = StrReplace(MessageText, "%Prepared2%", Enums.StatusesOfGoodsPickingPlacement.Prepared2);
			MessageText = StrReplace(MessageText, "%CompletedWithoutErrors%", Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors);
			
			CommonClientServer.MessageToUser(MessageText);
			
			DocumentsArray.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If DocumentsArray.Count() = 0 Then
		Return ArrayOfChangedDocuments;
	EndIf;
	
	For Each RowOfTables In DocumentsArray Do
		DocumentObject = RowOfTables.GetObject();
		Try
			DocumentObject.Lock();
			
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
			If AssignAssignee
				And ValueIsFilled(Performer) Then
				DocumentObject.Performer = Performer;
			EndIf;
			
			RefusalSelection = False;
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.GoodsPickingPlacement);
			
			If DocumentObject.GoodsFilter.Count() > 0 Then
				ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject,SeriesSpecificationParameters.Filter);
				ProductsServer.CheckSeriesCompletion(DocumentObject,SeriesSpecificationParameters.Filter,RefusalSelection,New Array);
			EndIf;
			
			FailurePlacement = False;
			If DocumentObject.GoodsPlacement.Count() > 0 Then
				ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject,SeriesSpecificationParameters.Location);
				ProductsServer.CheckSeriesCompletion(DocumentObject,SeriesSpecificationParameters.Location,FailurePlacement,New Array);
			EndIf;
			
			If Not RefusalSelection
				And Not FailurePlacement Then
				DocumentObject.Write(DocumentWriteMode.Posting);
				ArrayOfChangedDocuments.Add(RowOfTables);
			Else
				MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng từ %Document%.';
									|ru = 'Статус документа %Document% не изменен.';
									|en = 'Status of document %Document% is not changed.'; fa = 'Status of document %Document% is not changed.';
									|it = 'Lo stato del documento %Document% non è modificato.';
									|pl = 'Status dokumentu %Document% nie został zmieniony.';
									|tr = '%Document% belgesinin durumu değiştirilmedi.'");
				MessageText = StrReplace(MessageText,"%Document%",DocumentObject.Ref);
				
				CommonClientServer.MessageToUser(MessageText);
			EndIf;
		Except
			CommonClientServer.MessageToUser(ErrorInfo().Description);
		EndTry;
	EndDo;
	
	Return ArrayOfChangedDocuments;
EndFunction

// Changes the status of documents "Selection (placement) of goods" to " in progress"
//
//	Parameters:
//		DocumentsArray - Array - array of links to documents that need to change their status
//		AssignAssignee - Boolean - when setting the status, record the task performer
//		Performer - CatalogRef.Users - if Assign Executor = TRUE, then
//					the installed executor is passed in this parameter
//	Returns:
//		Array - array of links to documents that have changed the status.
//
Function TakeUpTheJobs(Val DocumentsArray, AssignAssignee, Performer) Export
		
	ArrayOfChangedDocuments = New Array;
	
	IndexOf = DocumentsArray.Count();
	
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		ArrRow = DocumentsArray[IndexOf];
		
		DocumentAttributes = Common.ObjectAttributesValues(ArrRow, "Status, Posted");
		If Not DocumentAttributes.Posted Then 
			MessageText = NStr("vi = 'Không thay đổi trạng thái chứng từ %Document%: có thể thay đổi trạng thái bằng bộ xử lý theo nhóm chỉ đối với các chứng từ đã kết chuyển.';
								|ru = 'Статус документа %Document% не изменен: групповой обработкой можно изменять статусы только для проведенных документов.';
								|en = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.'; fa = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.';
								|it = 'Lo stato del documento %Document% non è modificato: tramite elaborazione collettiva è possibile modificare lo stato solo per i documenti registrati.';
								|pl = 'Status dokumentu %Document% nie jest zmieniony: przetwarzaniem grupowym można zmieniać statusy tylko dla zatwierdzonych dokumentów.';
								|tr = 'Belge durumu %Document% değiştirilmedi: Grup işleme, yalnızca kaydedilen belgelerin durumlarını değiştirebilir.'");
			
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			
			CommonClientServer.MessageToUser(MessageText);
			
			DocumentsArray.Delete(IndexOf);
		ElsIf DocumentAttributes.Status <> Enums.StatusesOfGoodsPickingPlacement.Prepared2 Then
			
			MessageText = NStr("vi = 'Không thay đổi trạng thái chứng từ %Document%: bằng bộ xử lý theo nhóm có thể đặt trạng thái %InProgress% đối với chứng từ có trạng thái %Prepared2%.';
								|ru = 'Статус документа %Document% не изменен: групповой обработкой статус %InProgress% можно установить только для документов в статусе %Prepared2%.';
								|en = 'The %Document% document status is not changed: you can set the %InProgress% status by group processing only for documents in the %Prepared2% status.'; fa = 'The %Document% document status is not changed: you can set the %InProgress% status by group processing only for documents in the %Prepared2% status.';
								|it = 'Lo stato del documento %Document% non è modificato: lo stato %InProgress% può essere impostato solo per i documenti con lo stato %Prepared2% tramite l''elaborazione a blocchi.';
								|pl = 'Status dokumentu %Document% nie został zmieniony: grupowym traktowaniem status %InProgress% można ustawić tylko dla dokumentów o statusie %Prepared2%.';
								|tr = '%Document% belge durumu değiştirilmemiştir: grup işleme ile %InProgress% durumu yalnızca %Prepared2% durumundaki belgeler için ayarlanabilir.'");
			
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			MessageText = StrReplace(MessageText, "%InProgress%", Enums.StatusesOfGoodsPickingPlacement.InProgress);
			MessageText = StrReplace(MessageText, "%Prepared2%", Enums.StatusesOfGoodsPickingPlacement.Prepared2);
			
			CommonClientServer.MessageToUser(MessageText);
			
			DocumentsArray.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If DocumentsArray.Count() = 0 Then
		Return ArrayOfChangedDocuments;
	EndIf;
	
	For Each RowOfTables In DocumentsArray Do
		Try
			DocumentObject = RowOfTables.GetObject();
			
			DocumentObject.Lock();
			
			If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "ExecutionStartDate") Then
				DocumentObject.ExecutionStartDate = CurrentSessionDate();
			EndIf;
			
			DocumentObject.Status = Enums.StatusesOfGoodsPickingPlacement.InProgress;
			If AssignAssignee
				And ValueIsFilled(Performer) Then
				DocumentObject.Performer = Performer;
			EndIf;
			
			If DocumentObject.CheckFilling() Then
				DocumentObject.Write(DocumentWriteMode.Write);
				ArrayOfChangedDocuments.Add(DocumentObject.Ref);
			EndIf;
		Except
			CommonClientServer.MessageToUser(ErrorInfo().Description);
		EndTry;
		
	EndDo;
	
	Return ArrayOfChangedDocuments;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Server-side event handler Obrabatyvaniya of the stores directory.
//
Procedure WarehousesProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	Var SelectWarehouseGroup, Date, Warehouse,
		UseWarehouseManagemantSystemForGoodsIssue,
		UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		UseWarehouseManagemantSystemForGoodsReceipt, PantryDivision;
	
	// We check and extract parameters into variables
	//	if at least one processed parameter is passed, we do not use standard processing.
	StandardProcessing = Not Parameters.Property("SelectWarehouseGroup", SelectWarehouseGroup);
	StandardProcessing = Not Parameters.Property("Warehouse", Warehouse) And StandardProcessing;
	If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsIssue", Date)
		Or Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages", Date)
		Or Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsReceipt", Date) 
		Or Parameters.Property("PantryDivision", Date) Then
		StandardProcessing = False;
	EndIf;
	
	If StandardProcessing Then
		Return;
	EndIf;
	
	SearchString = Parameters.SearchString;
	If SearchString = Undefined Then
		SearchString = "";
	EndIf;
	
	QueryText = "
	|SELECT ALLOWED
	|	Warehouses.Ref          AS Warehouse,
	|	Warehouses.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	(&SearchTerms)
	|";
	
	// If there is a selection according to the order scheme, it is necessary to take into account the start date of using the order scheme.
	If Parameters.Filter.Property("UseWarehouseManagemantSystemForGoodsIssue",
			UseWarehouseManagemantSystemForGoodsIssue) Then
		ConditionText = "
			|Warehouses.UseWarehouseManagemantSystemForGoodsIssue";
		If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsIssue")
			And ValueIsFilled(Date) Then
			ConditionText = ConditionText + "
				|AND &DATE >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue";
		EndIf;
		If Not UseWarehouseManagemantSystemForGoodsIssue
			And ValueIsFilled(Date) Then
			ConditionText = "NOT (" + ConditionText +")";
		EndIf;
		QueryText = QueryText + " And " + ConditionText;
	EndIf;
	
	If Parameters.Filter.Property("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
			UseWarehouseManagemantSystemForGoodsSurplusesShortages) Then
		ConditionText = "
			|Warehouses.UseWarehouseManagemantSystemForGoodsSurplusesShortages";
		If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages")
			And ValueIsFilled(Date) Then
			ConditionText = ConditionText + "
				|AND &DATE >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages";
		EndIf;
		If Not UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
			ConditionText = "NOT (" + ConditionText +")";
		EndIf;
		QueryText = QueryText + " And " + ConditionText;
	EndIf;
	
	If Parameters.Filter.Property("UseWarehouseManagemantSystemForGoodsReceipt",
			UseWarehouseManagemantSystemForGoodsReceipt) Then
		ConditionText = "
				|Warehouses.UseWarehouseManagemantSystemForGoodsReceipt";
		If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsReceipt") Then
			ConditionText = ConditionText + "
				|AND &DATE >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt";
		EndIf;
		If Not UseWarehouseManagemantSystemForGoodsReceipt
			And ValueIsFilled(Date) Then
			ConditionText = "NOT (" + ConditionText +")";
		EndIf;
		QueryText = QueryText + " And " + ConditionText;
	EndIf;
	
	If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
		
		QueryText = QueryText + "
			|	AND Warehouses.IsFolder";
	ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
		
		QueryText = QueryText + "
			|	AND NOT Warehouses.IsFolder";
	EndIf;
	
	// If, for example, a group of warehouses is selected in the Order header, then when selecting a warehouse in PM, you need to select subordinates.
	If ValueIsFilled(Warehouse) Then
		
		QueryText = QueryText + "
			|	AND Warehouses.Ref IN HIERARCHY(&Warehouse)
			|	AND Warehouses.SelectGroup IN (&SelectWarehouseGroup)";
	
	ElsIf ValueIsFilled(SelectWarehouseGroup) Then
		
		QueryText = QueryText + "
			|	AND (NOT Warehouses.IsFolder
			|	OR Warehouses.SelectGroup IN (&SelectWarehouseGroup))";
	EndIf;
	
	If Parameters.Property("PantryDivision", PantryDivision) Then
		QueryText = QueryText + "
			|	AND (NOT Warehouses.ShopFloorStockroom
			|	OR Warehouses.Department = &PantryDivision)";
	EndIf; 
	
	QueryText = QueryText + "
	|	ORDER BY Warehouses.Description";
	
	SearchTerms = "Warehouses.Description LIKE &SearchString ESCAPE ""~""";
	
	For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
		
		If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
			
			LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
			If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
				
				Continue;
				
			EndIf;
			
			AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
			SearchTerms = SearchTerms + "
			|	OR " + StringFunctionsClientServer.SubstituteParametersToString("Warehouses.%1 LIKE &SearchString ESCAPE ""~""",
				AttributesNames["Description"]);
			
		EndIf;
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SearchTerms", SearchTerms);
	
	Query = New Query(QueryText);
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	Query.SetParameter("SelectWarehouseGroup", SelectWarehouseGroup);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Date", Date);
	Query.SetParameter("PantryDivision", PantryDivision);

	QueryResult = Query.Execute();
	
	ChoiceData = New ValueList();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			ChoiceStructure = New Structure("Value", Selection.Warehouse);
			If Selection.DeletionMark Then
				ChoiceStructure.Insert("DeletionMark", Selection.DeletionMark);
			EndIf;
			ChoiceData.Add(ChoiceStructure);
		EndDo;
		
	EndIf;
	
EndProcedure

// Server handler for the event processingreceiving data From the enumeration of operationsreferences of inventory items.
//
Procedure TypesOfOperationsForAdjustingBalanceOfGoodsProcessingReceiptOfSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	If Not Parameters.Property("Filter")
		Or Parameters.Filter.Count() = 0 Then
	
		StandardProcessing = False;
		
		ChoiceData = New ValueList;
		
		ChoiceData.Add(
			Enums.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus, 
			String(Enums.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus));
		
		ChoiceData.Add(
			Enums.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage, 
			String(Enums.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage));
			
		ChoiceData.Add(
			Enums.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote,
			String(Enums.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote));	
			
		EndIf;
EndProcedure

// Server handler for the event processingreceiving data Selection of the list Statusordersreference.
//
Procedure StatusesOfMoveOrdersProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	SearchString = Parameters.SearchString;
	If SearchString = Undefined Then
		SearchString = "";
	EndIf;
	
	ChoiceData = New ValueList();
	StatusUnderReview = Enums.TransferNoteStatuses.DuringChecking;
	For Each Value In Enums.TransferNoteStatuses Do
		If Value = StatusUnderReview Then
			Continue;
		EndIf;
		If SearchString = Left(Value.Metadata().Presentation(),StrLen(SearchString)) Then
			ChoiceData.Add(Value);
		EndIf;
	EndDo;	
	
EndProcedure

Function GetDefaultWarehouse(Val Warehouse = Undefined, ConsiderWarehouseGroups = False, ExcludeGroupsAvailableInOrders = False) Export
	
	Return SettingsValueCached.GetDefaultWarehouse(Warehouse, ConsiderWarehouseGroups, ExcludeGroupsAvailableInOrders);
	
EndFunction 

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// We save error identifiers before recording for later removal of irrelevant errors
	
	ThisIsAnAddendum = Replacing = False
		Or Common.IsRecordSetAddition(Replacing);
	
	ErrorIds = Undefined; 
	If Not ThisIsAnAddendum
		And Not AdditionalProperties.Property("CompleteCalculation")
		And EstablishedSelectionCompliesWithRules() Then
		
		Query = New Query();
		Query.SetParameter("EmptyErrorId", New UUID("00000000-0000-0000-0000-000000000000"));
		Query.Text = 
		"SELECT
		|	CurrentTable.ErrorID AS ErrorID
		|FROM
		|	InformationRegister.CacheOfOrderStructureMasterData AS CurrentTable
		|WHERE
		|	&FilterCriterion
		|	AND CurrentTable.ErrorID <> &EmptyErrorId
		|";
		
		Common.FilterSetRecordsFromDatabase(ThisObject, Replacing, Query);
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			ErrorIds = QueryResult.Unload().UnloadColumn(0);
		EndIf;
		
	EndIf;
	
	AdditionalProperties.Insert("ErrorIdsBeforeWrite", ErrorIds);

	// Filling in the service data
	
	RecordSeparators  = New Map;
	
	CurCurrentSeparator = Undefined;
	CurrentOrder       = Undefined;
	
	For Each Record In ThisObject Do
		
		If CurrentOrder <> Record.ProductionOrder Then
			
			CurrentOrder = Record.ProductionOrder;
			CurCurrentSeparator = RecordSeparators[CurrentOrder];
			
			If CurCurrentSeparator = Undefined Then
				CurCurrentSeparator = New UUID();
				RecordSeparators.Insert(CurrentOrder, CurCurrentSeparator);
			EndIf;
			
		EndIf;
		
		Record.Separator = CurCurrentSeparator;
		
		If Record.ToPlan
			And Record.SupplyType = Enums.SupplyTypes.Production Then
			
			Record.ProductItemsGroup = OrderStructure.ProductGroupChecksum(Record);
			
		Else
			
			Record.ProductItemsGroup = "";
			
		EndIf;
		
		Record.ErrorID = Undefined;
		
		If Record.ToPlan
			And Record.BillOfMaterials.IsEmpty() And Record.SupplyType = Enums.SupplyTypes.Production Then
			
			Record.ErrorID = New UUID();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Removing irrelevant errors
	
	ErrorIds = AdditionalProperties.ErrorIdsBeforeWrite; // Array
	
	If ValueIsFilled(ErrorIds) Then
		
		DeletedErrors = CommonClientServer.ArraysDifference(ErrorIds, UnloadColumn("ErrorID"));
		
		ErrorsStructure = New Structure();
		ErrorsStructure.Insert("ErrorType", Enums.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs);
		ErrorsStructure.Insert("Errors", DeletedErrors);
		
		InformationRegisters.OrderStructureCalculationProtocol.RemoveErrors(ErrorsStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function EstablishedSelectionCompliesWithRules()
	
	HasErrors = False;
	
	FieldsStructure = Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions;
	
	For Each Field In FieldsStructure Do
		
		If Not ThisObject.Filter[Field.Name].Use Or ThisObject.Filter[Field.Name].ComparisonType = ComparisonType.Equal Then
			Continue;
		EndIf;
		
		HasErrors = True;
		Break;
		
	EndDo;
	
	If HasErrors Then
		
		FiltersList = New Array();
		
		For Each Item In Filter Do
			Template = NStr("vi = '""%1"" ""%2"" ""%3""';
							|ru = '""%1"" ""%2"" ""%3""';
							|en = '""%1"" ""%2"" ""%3""'; fa = '""%1"" ""%2"" ""%3""';
							|it = '""%1"" ""%2"" ""%3""';
							|pl = '""%1"" ""%2"" ""%3""';
							|tr = '""%1"" ""%2"" ""%3""'");
			MessageText = StrTemplate(Template, Item.Name, Item.ComparisonType, Item.Value)
				+ ?(Item.Use, "", " " + NStr("vi = '(không sử dụng)';
											|ru = '(не используется)';
											|en = '(not used)'; fa = '(not used)';
											|it = '(non utilizzato)';
											|pl = '(nieużywane)';
											|tr = '(kullanılmamaktadır)'"));
			FiltersList.Add(MessageText);
		EndDo;
		
		ExceptionText = StrTemplate(NStr("vi = 'Không hỗ trợ bộ lọc đã đặt %1';
										|ru = 'Установленный отбор не поддерживается %1';
										|en = 'The set filter is not supported %1'; fa = 'The set filter is not supported %1';
										|it = 'Il filtro impostato non è supportato %1';
										|pl = 'Ustawiony filtr nie jest obsługiwany %1';
										|tr = 'Yapılandırılan filtre desteklenmemektedir %1'"), StrConcat(FiltersList, "; "));
		Raise ExceptionText;
		
	EndIf;

	Return True;
	
EndFunction

#EndRegion

#EndIf

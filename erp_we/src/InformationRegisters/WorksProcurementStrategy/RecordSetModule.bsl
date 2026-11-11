#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// In general, the props are additional. the ordering is updated
	UpdatePropsForOrdering = True;
	
	If AdditionalProperties.Property("UpdatePropsForOrdering") Then
		
		UpdatePropsForOrdering = AdditionalProperties.UpdatePropsForOrdering;
		
	EndIf;
	
	// Updating the additional props. ordering
	If UpdatePropsForOrdering Then
	
		// A table of values that stores the maximum values of the additional props. ordering for the combination of nomenclature, characteristic.
		ValuesOfDetailsForOrdering = Undefined;
		
		If Count() > 0 Then
			
			// Setting a lock
			SetLock(Filter);
			
			// Processing Set records
			For Each InformationRegisterRecord In ThisObject Do
			
				// The value of the additional props is not set for the record. ordering
				If InformationRegisterRecord.AddlOrderingAttribute = 0 Then
					
					InformationRegisterRecord.AddlOrderingAttribute = NewValueForOrderingProps(InformationRegisterRecord, ValuesOfDetailsForOrdering);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
		
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	// In general, the props are additional. the ordering is updated
	UpdatePropsForOrdering = True;
	
	If AdditionalProperties.Property("UpdatePropsForOrdering") Then
		
		UpdatePropsForOrdering = AdditionalProperties.UpdatePropsForOrdering;
		
	EndIf;
	
	// Updating the additional props. ordering
	If UpdatePropsForOrdering Then
			
		UpdatePropsValuesForOrdering(Filter);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query(
	"SELECT
	|	CAST(Records.ProcurementStrategy AS Catalog.ProcurementStrategies) AS ProcurementStrategy
	|INTO Records
	|FROM
	|	&Records AS Records
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Records.ProcurementStrategy.SupplyType AS FillError
	|FROM
	|	Records AS Records
	|WHERE
	|	Records.ProcurementStrategy.SupplyType     = VALUE(Enum.SupplyTypes.Move)
	|	OR Records.ProcurementStrategy.SupplyType = VALUE(Enum.SupplyTypes.AssemblyDisassembly)");
	
	Query.SetParameter("Records", Unload());
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		If Selection.FillError = Enums.SupplyTypes.Move Then
			MessageText = NStr("vi = 'Nhu cầu về công việc không được đảm bảo bằng việc điều chuyển nội bộ';
								|ru = 'Потребности в работах не обеспечиваются перемещением';
								|en = 'Demands for works are not fulfilled with the transfer'; fa = 'Demands for works are not fulfilled with the transfer';
								|it = 'Il fabbisogno di lavori non è garantito dai trasferimenti';
								|pl = 'Potrzeby w pracach nie są zaspokajane przemieszczeniem';
								|tr = 'İş gereklilikleri transfer ile karşılanmıyor'");
		Else
			MessageText = NStr("vi = 'Nhu cầu về công việc không được đảm bảo bằng việc đóng bộ/tách bộ';
								|ru = 'Потребности в работах не обеспечиваются сборкой/разборкой';
								|en = 'Demands for works are not fulfilled with kitting'; fa = 'Demands for works are not fulfilled with kitting';
								|it = 'I fabbisogni di lavori non sono garantiti dall''assemblaggio/disassemblaggio';
								|pl = 'Potrzeby w pracach nie są zaspokajane montaż/demontaż';
								|tr = 'İş gereklilikleri montaj/demontaj ile karşılanmıyor'");
		EndIf;
		CommonClientServer.MessageToUser(MessageText,, "ProcurementStrategy",, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function NewValueForOrderingProps(InformationRegisterRecord, ValuesOfDetailsForOrdering)
	
	AddlOrderingAttribute = 1;
	
	// Creating a table of values that stores the maximum values of the additional props. ordering for the combination of nomenclature, characteristic.
	If ValuesOfDetailsForOrdering = Undefined Then
		
		ValuesOfDetailsForOrdering = New ValueTable;
		ValuesOfDetailsForOrdering.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		ValuesOfDetailsForOrdering.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		ValuesOfDetailsForOrdering.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
		
	EndIf;
	
	// Search for the value of the additional details. ordering
	FoundRows = ValuesOfDetailsForOrdering.FindRows(New Structure("Products, Characteristic", InformationRegisterRecord.Products, InformationRegisterRecord.Characteristic));
	
	If FoundRows.Count() > 0 Then
		
		AddlOrderingAttribute = FoundRows[0].AddlOrderingAttribute + 1;
		FoundRows[0].AddlOrderingAttribute = AddlOrderingAttribute;
		
	Else
		
		NewRow = ValuesOfDetailsForOrdering.Add();
		
		NewRow.Products = InformationRegisterRecord.Products;
		NewRow.Characteristic = InformationRegisterRecord.Characteristic;
		
		Query = New Query(
		"SELECT TOP 1
		|	WorksProcurementStrategy.AddlOrderingAttribute AS AddlOrderingAttribute
		|FROM
		|	InformationRegister.WorksProcurementStrategy AS WorksProcurementStrategy
		|WHERE
		|	WorksProcurementStrategy.Products = &Products
		|	AND WorksProcurementStrategy.Characteristic = &Characteristic
		|
		|ORDER BY
		|	AddlOrderingAttribute DESC");
		
		Query.SetParameter("Products", InformationRegisterRecord.Products);
		Query.SetParameter("Characteristic", InformationRegisterRecord.Characteristic);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		If ValueIsFilled(Selection.AddlOrderingAttribute) Then
			
			AddlOrderingAttribute = Selection.AddlOrderingAttribute + 1;
			
		EndIf;
		
		NewRow.AddlOrderingAttribute = AddlOrderingAttribute;
		
	EndIf;
		
	Return AddlOrderingAttribute;
	
EndFunction

Procedure UpdatePropsValuesForOrdering(FilterParameters)
	
	// Setting a lock
	SetLock(FilterParameters);
	
	Query = New Query(
	"SELECT
	|	WorksProcurementStrategy.Products AS Products,
	|	WorksProcurementStrategy.Characteristic AS Characteristic,
	|	WorksProcurementStrategy.ProcurementStrategy AS ProcurementStrategy,
	|	WorksProcurementStrategy.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	CASE
	|		WHEN (WorksProcurementStrategy.Products = &Products
	|					OR (NOT &NomenclatureUsage))
	|				AND (WorksProcurementStrategy.Characteristic = &Characteristic
	|					OR (NOT &CharacteristicUse))
	|				AND (WorksProcurementStrategy.ProcurementStrategy = &ProcurementStrategy
	|					OR (NOT &WayToEnsureNeedsOfUse))
	|			THEN 0
	|		ELSE 1
	|	END AS Priority
	|FROM
	|	InformationRegister.WorksProcurementStrategy AS WorksProcurementStrategy
	|WHERE
	|	(WorksProcurementStrategy.Products = &Products
	|			OR (NOT &NomenclatureUsage))
	|	AND (WorksProcurementStrategy.Characteristic = &Characteristic
	|			OR (NOT &CharacteristicUse))
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	AddlOrderingAttribute,
	|	Priority");
	
	Query.SetParameter("Products", FilterParameters.Products.Value);
	Query.SetParameter("NomenclatureUsage", FilterParameters.Products.Use);
	Query.SetParameter("Characteristic", FilterParameters.Characteristic.Value);
	Query.SetParameter("CharacteristicUse", FilterParameters.Characteristic.Use);
	Query.SetParameter("ProcurementStrategy", FilterParameters.ProcurementStrategy.Value);
	Query.SetParameter("WayToEnsureNeedsOfUse", FilterParameters.ProcurementStrategy.Use);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		OrderingAttributeValues = 0;
		PreviousRecord = New Structure("Products, Characteristic");
		
		// Creating a recordset
		RecordSet = InformationRegisters.WorksProcurementStrategy.CreateRecordSet();
		
		// Setting selections
		RecordSet.Filter.Products.Value = FilterParameters.Products.Value;
		RecordSet.Filter.Products.Use = FilterParameters.Products.Use;
		RecordSet.Filter.Characteristic.Value = FilterParameters.Characteristic.Value;
		RecordSet.Filter.Characteristic.Use = FilterParameters.Characteristic.Use;
		
		// Setting additional properties
		RecordSet.AdditionalProperties.Insert("UpdatePropsForOrdering", False);
		
		// Sample Processing
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			// The entry does not differ from the previous one
			If Selection.Products = PreviousRecord.Products And Selection.Characteristic = PreviousRecord.Characteristic Then
				
				// The following ordering value
				OrderingAttributeValues = OrderingAttributeValues + 1;
				
			Else
				
				// Saving the current record
				FillPropertyValues(PreviousRecord, Selection);
				OrderingAttributeValues = 1;
				
			EndIf;
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			NewRecord.AddlOrderingAttribute = OrderingAttributeValues;
			
		EndDo;
		
		RecordSet.Write(True);
		
	EndIf;
	
EndProcedure

Procedure SetLock(FilterParameters)
	
	DataLock = New DataLock;
			
	LockItem = DataLock.Add("InformationRegister.WorksProcurementStrategy");
	LockItem.Mode = DataLockMode.Exclusive;
	
	If FilterParameters.Products.Use Then
		
		LockItem.SetValue("Products", FilterParameters.Products.Value);
		
	EndIf;
	
	If FilterParameters.Characteristic.Use Then
		
		LockItem.SetValue("Characteristic", FilterParameters.Characteristic.Value);
		
	EndIf;
	
	DataLock.Lock();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
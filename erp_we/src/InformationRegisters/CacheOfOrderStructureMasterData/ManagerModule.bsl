#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Performs replacement of specifications in the structure of production orders
//
// Parameters:
//  Replacement - Structure - contains the structure of the replacement parameters:
//  	* ProductionOrder	 - DocumentRef.ProductionOrder2_2		 - production order.
//  	* Products			 - CatalogRef.Products				 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics	 - Characteristics of the item.
//  	* Warehouse					 - CatalogRef.Warehouses						 - warehouse.
//  	* Purpose			 - CatalogRef.Assignments					 - purpose.
//  	* BillOfMaterials			 - CatalogRef.BillsOfMaterials		 - new specification.
//  Tasks - Assignment tables - if the parameter is passed, the tasks are added to the passed table, and not written to the database.
// Returns:
//   Boolean - replacement result.
//
Function ReplaceBOR(Replacement) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		
		LockItem = Block.Add("InformationRegister.CacheOfOrderStructureMasterData");
		
		LockItem.SetValue("Products",        Replacement.Products);
		LockItem.SetValue("Characteristic",      Replacement.Characteristic);
		LockItem.SetValue("Warehouse",               Replacement.Warehouse);
		LockItem.SetValue("Purpose",          Replacement.Purpose);
		LockItem.SetValue("ProductionOrder", Replacement.ProductionOrder);
		
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
	
		RecordSet = InformationRegisters.CacheOfOrderStructureMasterData.CreateRecordSet();
		
		RecordSet.Filter.Products.Set(Replacement.Products);
		RecordSet.Filter.Characteristic.Set(Replacement.Characteristic);
		RecordSet.Filter.Warehouse.Set(Replacement.Warehouse);
		RecordSet.Filter.Purpose.Set(Replacement.Purpose);
		RecordSet.Filter.ProductionOrder.Set(Replacement.ProductionOrder);
		
		RecordSet.Read();
		
		For Each Record In RecordSet Do
			
			BillOfMaterials = Record.BillOfMaterials; // The original bill of Materials
			
			Record.BillOfMaterials = Replacement.BillOfMaterials;
			
			If Record.SupplyType <> Enums.SupplyTypes.Production Then
				Record.ToPlan     = True;
				Record.SupplyType    = Enums.SupplyTypes.Production;
				Record.SupplyMethod = Catalogs.ProcurementStrategies.EmptyRef();
			EndIf;
			
			If BillOfMaterials <> Catalogs.BillsOfMaterials.EmptyRef() Then
				InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTaskCompleteCalculation(
					BillOfMaterials,
					Record.ProductionOrder);
			EndIf;
			
		EndDo;
		
		InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTaskCompleteCalculation(
			Replacement.BillOfMaterials,
			Replacement.ProductionOrder);
		
		RecordSet.Write(True);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
		
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Internal

// Performs a cache entry in the structure of production orders
//
// Parameters:
//  DataCache - ValueTable - contains replacement parameters:
//  	* ProductionOrder	 - DocumentRef.ProductionOrder2_2			 - production order.
//  	* Products			 - CatalogRef.Products					 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics		 - Characteristics of the item.
//  	* Warehouse					 - CatalogRef.Warehouses							 - warehouse.
//  	* Purpose			 - CatalogRef.Assignments						 - purpose.
//  	* ToPlan 		 - Boolean											 - the "schedule provision" flag.
//  	* SupplyType		 - EnumRef.SupplyTypes				 - type of security.
//  	* SupplyMethod		 - CatalogRef.ProcurementStrategies	 - the method of provision.
//  	* BillOfMaterials			 - CatalogRef.BillsOfMaterials			 - specification.
//  	* BOMIsPredefined		 - Boolean											 - indicates that the bill of materials from the order or the bill of materials of the semi-finished product produced in the process is specified.
//  	* ThisIsProductBeingDisassembled	 - Boolean											 - this is a disassembled finishedproduct.
//
Procedure WriteCachedValues(DataCache) Export
	
	OrderStructure.FillInAndRecordSetOfRecords(InformationRegisters.CacheOfOrderStructureMasterData.CreateRecordSet(), DataCache);
	
EndProcedure

// Performs cache replacement in the structure of production orders
//
// Parameters:
//  Substitutions_3 - ValueTable - contains replacement parameters:
//  	* ProductionOrder	 - DocumentRef.ProductionOrder2_2			 - production order.
//  	* Products			 - CatalogRef.Products					 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics		 - Characteristics of the item.
//  	* Warehouse					 - CatalogRef.Warehouses							 - warehouse.
//  	* Purpose			 - CatalogRef.Assignments						 - purpose.
//  	* ToPlan 		 - Boolean											 - plan production or relocation.
//  	* SupplyType		 - EnumRef.SupplyTypes				 - type of security.
//  	* SupplyMethod		 - CatalogRef.ProcurementStrategies	 - the method of provision.
//  	* BillOfMaterials			 - CatalogRef.BillsOfMaterials			 - specification.
//  	* BOMIsPredefined		 - Boolean											 - indicates that the bill of materials from the order or the bill of materials of the semi-finished product produced in the process is specified.
//  	* ThisIsProductBeingDisassembled	 - Boolean											 - this is a disassembled finishedproduct.
//
Procedure ReplaceCachedValues(Substitutions_3) Export
	
	ListOfProperties = "ToPlan,SupplyType,SupplyMethod,BillOfMaterials,BOMIsPredefined,ThisIsProductBeingDisassembled";
	
	For Each Replacement In Substitutions_3 Do

		TransactionActive = TransactionActive();
		
		If Not TransactionActive Then
			BeginTransaction();
		EndIf;
		
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add("InformationRegister.CacheOfOrderStructureMasterData");
			
			LockItem.SetValue("Products",        Replacement.Products);
			LockItem.SetValue("Characteristic",      Replacement.Characteristic);
			LockItem.SetValue("Warehouse",               Replacement.Warehouse);
			LockItem.SetValue("Purpose",          Replacement.Purpose);
			LockItem.SetValue("ProductionOrder", Replacement.ProductionOrder);
			
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
		
			RecordSet = InformationRegisters.CacheOfOrderStructureMasterData.CreateRecordSet();
			
			RecordSet.Filter.Products.Set(Replacement.Products);
			RecordSet.Filter.Characteristic.Set(Replacement.Characteristic);
			RecordSet.Filter.Warehouse.Set(Replacement.Warehouse);
			RecordSet.Filter.Purpose.Set(Replacement.Purpose);
			RecordSet.Filter.ProductionOrder.Set(Replacement.ProductionOrder);
			
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				
				BillOfMaterials = Record.BillOfMaterials; // The original bill of Materials
				
				FillPropertyValues(Record, Replacement, ListOfProperties);
				
				If BillOfMaterials <> Catalogs.BillsOfMaterials.EmptyRef() Then
					InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTaskCompleteCalculation(
						BillOfMaterials,
						Record.ProductionOrder);
				EndIf;
				
			EndDo;
			
			If Replacement.BillOfMaterials <> Catalogs.BillsOfMaterials.EmptyRef() Then
				InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTaskCompleteCalculation(
					Replacement.BillOfMaterials,
					Record.ProductionOrder);
			EndIf;
			
			RecordSet.Write(True);
			
			If Not TransactionActive Then
				CommitTransaction();
			EndIf;
			
		Except
			
			If Not TransactionActive Then
				RollbackTransaction();
			EndIf;
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText;
			
		EndTry;
	
	EndDo;
	
EndProcedure

// Deletes cached values.
// 
// Parameters:
// 	ProductionOrders - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
Procedure ClearCachedValues(Val ProductionOrders) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(ProductionOrders) = Type("Array") Then
		ProductionOrders = CommonClientServer.CollapseArray(ProductionOrders);
	Else
		ProductionOrders = CommonClientServer.ValueInArray(ProductionOrders);
	EndIf;
	
	For Each ProductionOrder In ProductionOrders Do
		
		RecordSet = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet();
		RecordSet.Filter.ProductionOrder.Set(ProductionOrder);
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

// Deletes cached values by keys (record separators).
// 
// Parameters:
//  List - ValueTable - contains replacement parameters:
//  	* ProductionOrder	 - DocumentRef.ProductionOrder2_2	 - production order.
//  	* Separator			 - UUID					 - the record separator.
Procedure DeleteCacheByKeys(List) Export
	
	NumberOfWriteAttempts = OrderStructureInternal.NumberOfWriteAttempts();
	
	Total = List.Count();
	IndexOf = 0;
	
	ErrorCounter = 1;
	
	While Total > IndexOf Do
		
		Var_Key = List[IndexOf];
		
		BeginTransaction();
		Try
			
			RecordSet = InformationRegisters.CacheOfOrderStructureMasterData.CreateRecordSet();
			RecordSet.Filter.ProductionOrder.Set(Var_Key.ProductionOrder);
			RecordSet.Filter.Separator.Set(Var_Key.Separator);
			RecordSet.Write(True);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			If ErrorCounter < NumberOfWriteAttempts Then
				OrderStructure.RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText);
				ErrorCounter = ErrorCounter + 1;
				Continue;
			EndIf;
			
			Raise ErrorText;
			
		EndTry;
		
		IndexOf = IndexOf + 1;
		ErrorCounter = 1;
		
	EndDo;

EndProcedure

#EndRegion

#EndIf
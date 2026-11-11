// @strict-types

#Region Internal

// Called when registering arbitrary data loading handlers.
// In this procedure, you need to supplement this table of values with information about the registered arbitrary
// data loading handlers.
// Parameters:
//	HandlersTable - ValueTable - Columns:
//	* MetadataObject - MetadataObject - when loading the data of which
//      the registered handler should be called.
//	* Handler - CommonModule - a general module that implements an arbitrary
//      data loading handler. A set of export procedures that should
//      to be implemented in the handler, depends on setting the values of the following
//      columns of the value table.
//	* Version - String - the version number of the data upload / download handler interface
//      supported by the handler.
//	* BeforeMapRefs - Boolean - flag of the need to call a handler before
//      matching links (in the original IS and in the Cur) related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable procedure can be implemented before providing links()
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - before matching the references of which
//          the handler was called,
//        Standard processing - Boolean - if the procedure is
//          set to False before providing links(), instead of the standard
//          link matching (searching for objects in the Cur IS with the same
//          natural key values that were unloaded from the IS source)
//          , the function Match Links() of the general module will be called in the procedure
//          Before the delivery of the links() whose value is the parameter Standardprocessing
//          it was set equal to False.
//          Parameters of the Match Links() function:
//            Container - Processing object.The
//              container manager used in the data upload process is the container manager. For more information, see the comment
//              to the program interface for processing the uploadingmediagercontainer,
//            the table of outgoing links - the table of assignments - containing information about links
//              unloaded from the source information system. Columns:
//                Source link - Any link is a link of the object of the original information security, which you want
//                  to match with the link in the Cur information security,
//                The remaining columns are equal to the fields of the object's natural key, which
//                  were passed to the function during the data upload process.
//                  Unloaded and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - tables of values, columns:
//            Source link - Any link is a link of an object unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - If the value
//          of this parameter is set to True in the procedure before the provision of links(), the mapping of links corresponding
//          to the Cur metadata object will not be performed.
//	* BeforeImportType - Boolean - flag for calling the handler before
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable Preload Type procedure() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - The data objectmetadata whose
//          handler was called before loading all the data,
//        Failure - Boolean - If the value of this
//          parameter is set to True in the Preload Type() procedure, all data objects corresponding to the Cur
//          metadata object will not be loaded.
//	* BeforeImportObject - Boolean -  flag for calling a handler before
//      loading a data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for preloading an object() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
//          the data object of the information database, before loading which the handler was called.
//          The value passed to the procedure before loading the object() as a parameter value
//          The object can be modified inside the handler procedure before loading the object().
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//        Failure - Boolean - if the value of this
//          parameter is set to True in the procedure for preloading the object(), the data object will not be loaded.
//	* AfterImportObject - Boolean - flag for whether a handler should be called after
//      loading a data object related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exported procedure for post-loading an object() can be implemented
//      that supports the following parameters:
//        Container - processingobject - Offload-Offload data of the Container manager
//          is the container manager used in the process of loading data. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, - Reference object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          Register of recordscountainment, sequence of recordscountainment, Recalculation of recordscountainment -
//          the data object of the information database, after loading which the handler was called.
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//	* AfterLoadingType - Boolean - flag for calling the handler after
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exportable post-loading Type() procedure can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	For Each Table In RecordsetTablesWithSupportForTotals() Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Table;
		NewHandler.Handler = ExportImportDataTotalsManagement;
		NewHandler.BeforeImportType = True;
		NewHandler.AfterLoadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// Executes handlers before loading a specific type of data.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	MetadataObject - MetadataObject - metadata object.
//	Cancel - Boolean - indicates whether this operation was performed.
//
Procedure BeforeImportType(Container, MetadataObject, Cancel) Export
	
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If CommonCTL.IsAccumulationRegister(MetadataObject)
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
		And Manager.GetAggregatesMode() Then
			
		Manager.SetAggregatesUsing(False);
		
	Else		
		
		Manager.SetTotalsUsing(False);
			
	EndIf;
	
EndProcedure

// See the description of the procedure for adding service events() to the general module of unloading and unloading service events.
// 
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager -
//	MetadataObject - MetadataObjectAccumulationRegister, MetadataObjectAccountingRegister, MetadataObjectInformationRegister -
//
Procedure AfterLoadingType(Container, MetadataObject) Export
	
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If CommonCTL.IsAccumulationRegister(MetadataObject)
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
		And Manager.GetAggregatesMode() Then
			
		Manager.SetAggregatesUsing(True);
		
	Else		
		
		Manager.SetTotalsUsing(True);
			
	EndIf;
	
	If (CommonCTL.IsAccumulationRegister(MetadataObject) 
		And MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance) 
		Or CommonCTL.IsAccountingRegister(MetadataObject) Then
		
		If Not Manager.GetPresentTotalsUsing() Then
			Manager.SetPresentTotalsUsing(True);
		EndIf;
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Private

// Returns:
// 	Array of MetadataObject - 
//
Function RecordsetTablesWithSupportForTotals()
	
	Result = New Array; // Array of MetadataObject
	
	FillInSetsTableByMetadataCollection(Result, Metadata.InformationRegisters);
	FillInSetsTableByMetadataCollection(Result, Metadata.AccumulationRegisters);
	FillInSetsTableByMetadataCollection(Result, Metadata.AccountingRegisters);
	
	Return Result;
	
EndFunction

Procedure FillInSetsTableByMetadataCollection(Sets, Collection)
	
	For Each MetadataObject In Collection Do
		
		If CommonCTL.IsRecordSetSupportingTotals(MetadataObject) Then
			Sets.Add(MetadataObject);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
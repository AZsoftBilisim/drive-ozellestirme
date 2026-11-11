
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.AlternativeMaterials.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.84";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a017c4fc-f9c7-449c-b476-03eb0ad7aaa0");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.AlternativeMaterials.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi thông tin ""Vật tư tương tự của nguyên vật liệu"".';
							|ru = 'Актуализация движений по регистру сведений ""Аналоги материалов"".';
							|en = 'Update records of the ""Substitutes"" information register.'; fa = 'Update records of the ""Substitutes"" information register.';
							|it = 'Update records of the ""Substitutes"" information register.';
							|pl = 'Update records of the ""Substitutes"" information register.';
							|tr = '""Malzeme ikameleri"" bilgi kayıt tablosundaki kayıtların güncellenmesi.'");
	
	ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = ExecutionPriorities.Add();
	Priority.Order = "After";
	Priority.Procedure = "Documents.EngineeringChangeOrder.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionPriorities = ExecutionPriorities;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EngineeringChangeOrder.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.AlternativeMaterials.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.AlternativeMaterials.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.AlternativeMaterials.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Registers documents for processing to modify records.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.AlternativeMaterials";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.EngineeringChangeOrder";
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Ref.ReplacementOption AS ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	SUM(DocumentData.QuantityOfMaterials) AS QuantityOfMaterials,
	|	SUM(DocumentData.NumberOfAnalogues) AS NumberOfAnalogues
	|INTO ReplacementPermissionData
	|FROM
	|	(SELECT
	|		PermissionToReplaceMaterialsMaterials.Ref AS Ref,
	|		SUM(1) AS QuantityOfMaterials,
	|		0 AS NumberOfAnalogues
	|	FROM
	|		Document.EngineeringChangeOrder.UsedMaterials AS PermissionToReplaceMaterialsMaterials
	|	
	|	GROUP BY
	|		PermissionToReplaceMaterialsMaterials.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EngineeringChangeOrderSubstitutes.Ref,
	|		0,
	|		SUM(1)
	|	FROM
	|		Document.EngineeringChangeOrder.Substitutes AS EngineeringChangeOrderSubstitutes
	|	
	|	GROUP BY
	|		EngineeringChangeOrderSubstitutes.Ref) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Ref.ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders
	|
	|INDEX BY
	|	ReplacementOption,
	|	UseItForAutocorrectInOrders,
	|	QuantityOfMaterials,
	|	NumberOfAnalogues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPermissionData.Ref AS Ref,
	|	ReplacementPermissionData.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrdersInDocument,
	|	CASE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SubstituteList)
	|			THEN TRUE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SetToSet)
	|			THEN ReplacementPermissionData.QuantityOfMaterials = 1
	|					AND ReplacementPermissionData.NumberOfAnalogues = 1
	|		ELSE FALSE
	|	END AS UseItForAutocorrectInInstallationOrders
	|INTO TableApplicationInOrders
	|FROM
	|	ReplacementPermissionData AS ReplacementPermissionData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EngineeringChangeOrder.Ref AS Ref
	|FROM
	|	Document.EngineeringChangeOrder AS EngineeringChangeOrder
	|WHERE
	|	EngineeringChangeOrder.Posted
	|	AND EngineeringChangeOrder.Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|			WHERE
	|				AlternativeMaterials.Recorder = EngineeringChangeOrder.Ref
	|				AND (AlternativeMaterials.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.EmptyRef)
	|					OR AlternativeMaterials.Count = 0
	|					OR (TRUE IN
	|							(SELECT TOP 1
	|								TRUE
	|							FROM
	|								TableApplicationInOrders AS TableApplicationInOrders
	|							WHERE
	|								TableApplicationInOrders.Ref = AlternativeMaterials.Recorder
	|								AND TableApplicationInOrders.UseItForAutocorrectInInstallationOrders <> AlternativeMaterials.UseItForAutocorrectInOrders))))";
		
	Query = New Query(QueryText);
	Recorders = Query.Execute().Unload().UnloadColumn("Ref");
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
		
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	Parameters.ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(
									"Document.EngineeringChangeOrder",
									"InformationRegister.AlternativeMaterials",
									Parameters.Queue,
									AdditionalParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FillInTypesOfMetadata();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableObjects

&AtClient
Procedure TableObjectsValueChoice(Item, Value, StandardProcessing)
	If Not ValueIsFilled(Value) Then
		Return
	EndIf;
	Result = SelectedIdentifiersOfMetadataObjects(Value);
	Close(Result);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMetadataKinds

&AtClient
Procedure MetadataKindsOnActivateRow(Item)
	AttachIdleHandler("ProcessRowActivationTypesOfMetadata",0.2,True);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTypesOfMetadata()
	
	SupportedTypesOfMetadata = UserNotificationsOfEvents.SupportedTypesOfMetadata();
	For Each MetadataKind In SupportedTypesOfMetadata Do
		NewRow = MetadataKinds.Add();
		NewRow.Kind = MetadataKind.Name;
		NewRow.Synonym = MetadataKind.Synonym;
		NewRow.PictureIndex = UserNotificationsOfEvents.IndexesOfImagesByType()[MetadataKind.Name];
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInMetadataObjectsByType(MetadataKind)
	
	SourcesOfNotificationExceptions = UserNotificationsOfEventsCached.SourcesOfNotificationExceptions();
	
	TableObjects.Clear();
	MetadataObjectCollection = Metadata[MetadataKind];
	For Each MetadataObject In MetadataObjectCollection Do
		FullName = MetadataObject.FullName();
		If AccessRight("View", MetadataObject)
			And Not StrStartsWith(MetadataObject.Name, "Delete") 
			And SourcesOfNotificationExceptions.Find(FullName) = Undefined Then
			
			NewItem = TableObjects.Add();
			NewItem.Description = MetadataObject.Presentation();
			NewItem.FullName = FullName;
			NewItem.PictureIndex = UserNotificationsOfEvents.PictureIndex(NewItem.FullName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessRowActivationTypesOfMetadata()
	CurrentData = Items.MetadataKinds.CurrentData;
	If CurrentData <> Undefined Then
		FillInMetadataObjectsByType(CurrentData.Kind);
	EndIf;
EndProcedure

&AtServer
Function SelectedIdentifiersOfMetadataObjects(RowsIDs)
	
	NamesArray = New Array;
	
	ResultingArray = New Array;
	
	For Each ID In RowsIDs Do
		CurRow = TableObjects.FindByID(ID);
		NamesArray.Add(CurRow.FullName);
		ResultingStructure = StructureOfSelectionResult();
		FillPropertyValues(ResultingStructure, CurRow);
		ResultingArray.Add(ResultingStructure);
	EndDo;
	
	Result = New Map;
	ObjectsIDs = Common.MetadataObjectIDs(NamesArray, False);
	For Each ResultRow In ResultingArray Do
		ResultRow.SourceDetails_ = UserNotificationsOfEvents.StandardAttribute(Common.MetadataObjectByFullName(ResultRow.FullName));
		Result.Insert(ObjectsIDs.Get(ResultRow.FullName), ResultRow);
	EndDo;
	
	Return Result
EndFunction

&AtServer
Function StructureOfSelectionResult()
	ResultingStructure = New Structure();
	ResultingStructure.Insert("PictureIndex");
	ResultingStructure.Insert("Description");
	ResultingStructure.Insert("FullName");
	ResultingStructure.Insert("SourceDetails_");
	Return ResultingStructure
EndFunction

#EndRegion
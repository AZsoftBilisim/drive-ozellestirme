#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FileOwner", FileOwner);
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.6.1") Then
		Parameters.Property("ID", FileID);
		Parameters.Property("Description", FileDescription);
		Parameters.Property("CurrentVersionID", CurrentVersionID);
		FillInFileVersions();
	Else
		Items.ConnectionPageGroup.CurrentPage = Items.PageFunctionalityUnavailable;
	EndIf;
	
	Items.VersionsNumber.Visible =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18");
	
EndProcedure

&AtServer
Procedure FillInFileVersions(RefreshEnabled = False)
	
	Versions.Clear();
	If Not ValueIsFilled(FileID) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentVersionID) Or RefreshEnabled Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		FileInfo1 = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			"DMFile",
			FileID,
			"activeVersion");
		CurrentVersionID = FileInfo1.activeVersion.objectID.ID;
	EndIf;
	
	FileVersions = IntegrationWith1CDocumentManagementCoreServerCall.FileVersions(FileID);
	For Each ListObject_ In FileVersions Do
		FileVersion = ListObject_.object;
		VersionString = Versions.Add();
		VersionString.Id = FileVersion.objectID.ID;
		VersionString.Extension = FileVersion.extension;
		
		DeletionMark = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileVersion, "deletionMark") Then
			DeletionMark = FileVersion.deletionMark;
		EndIf;
		VersionString.PictureIndex =
			IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
				VersionString.Extension,
				DeletionMark);
		
		VersionString.Description = FileVersion.name;
		VersionString.Size = FileVersion.size;
		VersionString.CreationDate = FileVersion.creationDate;
		VersionString.Active_ = (VersionString.Id = CurrentVersionID);
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileVersion, "author") Then
			VersionString.Author = FileVersion.author.name;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				FileVersion, "modificationDateUniversal") Then
			VersionString.ModificationDate = ToLocalTime(FileVersion.modificationDateUniversal);
		Else
			VersionString.ModificationDate = FileVersion.modificationDate;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileVersion, "comment") Then
			VersionString.Comment = FileVersion.comment;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileVersion, "number") Then
			VersionString.Number = FileVersion.number;
		EndIf;
	EndDo;
	
	Versions.Sort("CreationDate DESC");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVersions

&AtClient
Procedure VersionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Versions.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFileVersion(
			CurrentData.Id,
			CurrentData.Description,
			CurrentData.Extension,
			UUID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	RefreshVersionList();
	
EndProcedure

&AtClient
Procedure OpenForViewing(Command)
	
	CurrentData = Items.Versions.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFileVersion(
			CurrentData.Id,
			CurrentData.Description,
			CurrentData.Extension,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure MakeActive(Command)
	
	CurrentData = Items.Versions.CurrentData;
	If CurrentData <> Undefined Then
		CallbackDescription = New CallbackDescription("MakeActiveCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.MakeVersionActive(
			FileDescription,
			FileID,
			FileOwner,
			CurrentData.Id,
			CallbackDescription,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	CurrentData = Items.Versions.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.SaveVersionAs(
			CurrentData.Id,
			CurrentData.Description,
			CurrentData.Extension,
			UUID);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MakeActiveCompletion(Result, Var_Parameters) Export
	
	CurrentVersionID = "";
	RefreshVersionList();
	
EndProcedure

&AtClient
Procedure RefreshVersionList()
	
	If Items.Versions.CurrentData = Undefined Then
		CurrentRow = Undefined;
	Else
		CurrentRow = Items.Versions.CurrentData.GetID();
	EndIf;
	
	FillInFileVersions(True);
	
	Items.Versions.CurrentRow = CurrentRow;
	
EndProcedure

#EndRegion
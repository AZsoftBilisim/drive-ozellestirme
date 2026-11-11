
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	ReadOnly = Not Parameters.Property("ManualSetting");
	
	Initialize();
	SetVisibility1();
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataSourceOnChange(Item)
	
	Object.DataSourcePresentation = Item.EditText;
	DataSourceWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write();
	Close();
	
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	
	Write();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DataSourceWhenModifiedOnServer()
	
	Object.RegisterIndicators.Clear();
	RegisterIndicators = Catalogs.BusinessTransactionsSettings.RegisterIndicators(Object.DataSource);
	If RegisterIndicators <> Undefined Then
		For Each Factor In RegisterIndicators Do
			NewRow = Object.RegisterIndicators.Add();
			NewRow.Factor = Factor.Key;
			NewRow.Use = True;
		EndDo;
		Object.RegisterIndicators.Sort("Factor");
	EndIf;
EndProcedure

&AtServer
Procedure Initialize()
	
	ParentOfDocuments = Common.MetadataObjectID("Documents");
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Parent", ParentOfDocuments));
	Items.DocumentsMetadataObjectID.ChoiceParameters = New FixedArray(ParametersArray);
	
	// Initialize the list of functional options
	For Each DescriptionOfOption In Metadata.FunctionalOptions Do
		TypeOfOption = DescriptionOfOption.Location.Type.Types();
		If TypeOfOption.Count() = 1 And TypeOfOption[0] = Type("Boolean") Then
			Items.FunctionalOptionsFunctionalOptionName.ChoiceList.Add(DescriptionOfOption.Name, DescriptionOfOption.Synonym);
		EndIf;
	EndDo;
	
	// Initializing the list of data sources
	RegistersList = DataSourcesCached.AvailableDataSources();
	For Each Register In RegistersList Do
		Items.DataSource.ChoiceList.Add(Register.Value,Register.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.FormWriteAndClose.Visible = Not ReadOnly;
	Items.FormWrite.Visible = Not ReadOnly;
	Items.FormClose.Visible = ReadOnly;
	
	Items.Documents.CommandBar.Visible = Not ReadOnly;
	Items.FunctionalOptions.CommandBar.Visible = Not ReadOnly;
	
EndProcedure

#EndRegion

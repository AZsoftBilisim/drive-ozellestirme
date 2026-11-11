#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	RaiseExceptionWhenCreating = True;
	
	RaiseExceptionWhenCreating = RaiseExceptionWhenCreating
								   And Not GetFunctionalOption("UseProduction");
	
	RaiseExceptionWhenCreating = RaiseExceptionWhenCreating
								   And Not GetFunctionalOption("ComplexAutomation");
	
	If RaiseExceptionWhenCreating Then
		MessageText = NStr("vi = 'Không được phép mở trực tiếp biểu mẫu danh sách danh mục ""Mức độ ưu tiên"".';
							|ru = 'Непосредственное открытие формы списка справочника ""Приоритеты"" не предусмотрено.';
							|en = 'Cannot directly open the ""Priorities"" catalog list form.'; fa = 'Cannot directly open the ""Priorities"" catalog list form.';
							|it = 'Apertura diretta del modulo dell''elenco della directory ""Priorità"" non è prevista.';
							|pl = 'Bezpośrednie otwieranie formularza listy ""Приоритеты"" nie jest przewidziane.';
							|tr = '""Öncelikler"" kataloğunun liste formunun doğrudan açılması sağlanmadı.'");
		Raise MessageText;
	EndIf;

	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	AvailableUpdate = AccessRight("Update", Metadata.Catalogs.Priorities);
	
	Items.GroupSequenceChange.Enabled = AvailableUpdate;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

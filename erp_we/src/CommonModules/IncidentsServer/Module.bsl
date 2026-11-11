#Region Internal

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If AccessRight("InteractiveInsert", Metadata.Catalogs.Incidents) Then
		Command = Commands.Add();
		Command.Kind = "Organizer";
		Command.Presentation = NStr("vi = 'Tạo mới sự cố';
									|ru = 'Создать инцидент';
									|en = 'Create an incident'; fa = 'Create an incident';
									|it = 'Создать инцидент';
									|pl = 'Utwórz incydent';
									|tr = 'Olay oluştur'");
		Command.FunctionalOptions = "UseIncidents";
		Command.ParameterType = Metadata.DefinedTypes.IncidentSubject.Type;
		Command.WriteMode = "NotWrite";
		Command.Order = 50;
		Command.Handler = "IncidentsClient.CreateIncidentBySubject";
		Command.MultipleChoice = False;
	EndIf;
	
EndProcedure

#EndRegion

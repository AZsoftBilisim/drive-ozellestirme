///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Bộ xử lý bổ sung của tôi (%1)';
				|ru = 'Мои дополнительные обработки (%1)';
				|en = 'My additional data processors (%1)'; fa = 'My additional data processors (%1)';
				|it = 'I miei elaborati aggiuntivi (%1)';
				|pl = 'Moje dodatkowe procedury przetwarzania (%1)';
				|tr = 'Ek veri işlemcilerim (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	ElsIf Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo bổ sung của tôi (%1)';
				|ru = 'Мои дополнительные отчеты (%1)';
				|en = 'My additional reports (%1)'; fa = 'My additional reports (%1)';
				|it = 'I miei report aggiuntivi (%1)';
				|pl = 'Moje raporty dodatkowe (%1)';
				|tr = 'Ek raporlarım (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	EndIf;
	
	CommandsTypes = New Array;
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ClientMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.OpeningForm);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.SafeModeScenario);
	
	AdditionalCommands = AdditionalReportsAndDataProcessors.AdditionalCommands(Parameters.DataProcessorsKind, 
		Parameters.SectionRef, , CommandsTypes, False);
	UsedCommands.Load(AdditionalCommands);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UncheckAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = False;
	EndDo;
EndProcedure

&AtClient
Procedure CheckAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = True;
	EndDo;
EndProcedure

&AtClient
Procedure OK(Command)
	WriteUserDataProcessorsSet();
	NotifyChoice("MyReportsAndDataProcessorsSetupDone");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteUserDataProcessorsSet()
	Table = UsedCommands.Unload();
	Table.Columns.Ref.Name        = "AdditionalReportOrDataProcessor";
	Table.Columns.Id.Name = "CommandID";
	Table.Columns.Use.Name = "Available";
	DimensionValues = New Structure("User", Users.AuthorizedUser());
	ResourcesValues  = New Structure;
	SetPrivilegedMode(True);
	InformationRegisters.DataProcessorAccessUserSettings.WriteSettingsPackage(Table, DimensionValues, ResourcesValues, False);
EndProcedure

#EndRegion

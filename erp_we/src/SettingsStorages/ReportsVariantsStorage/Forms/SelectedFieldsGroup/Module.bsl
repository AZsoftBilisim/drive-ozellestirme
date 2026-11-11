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
	
	DefineBehaviorInMobileClient();
	
	Parameters.Property("GroupTitle", GroupTitle);
	
	Placement = Undefined;
	If Not Parameters.Property("Placement", Placement) Then
		Raise NStr("vi = 'Chưa chuyển tham số phụ trợ ""Vị trí"".';
					|ru = 'Не передан служебный параметр ""Расположение"".';
					|en = 'Location service parameter has not been passed.'; fa = 'Location service parameter has not been passed.';
					|it = 'Il parametro di servizio ""Posizione"" non è stato trasmesso.';
					|pl = 'Nie przekazano parametru serwisowego ""Położenie"".';
					|tr = '""Konum"" servis parametresi verilmedi.'");
	EndIf;
	If Placement = DataCompositionFieldPlacement.Auto Then
		GroupPlacement = "Auto";
	ElsIf Placement = DataCompositionFieldPlacement.Vertically Then
		GroupPlacement = "Vertically";
	ElsIf Placement = DataCompositionFieldPlacement.Together Then
		GroupPlacement = "Together";
	ElsIf Placement = DataCompositionFieldPlacement.Horizontally Then
		GroupPlacement = "Horizontally";
	ElsIf Placement = DataCompositionFieldPlacement.SpecialColumn Then
		GroupPlacement = "SpecialColumn";
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sai giá trị tham số ""Vị trí"": ""%1"".';
																			|ru = 'Некорректное значение параметра ""Расположение"": ""%1"".';
																			|en = 'Location parameter contains invalid value: %1.'; fa = 'Location parameter contains invalid value: %1.';
																			|it = 'Il valore del parametro ""Posizione"" è errato: ""%1"".';
																			|pl = 'Niepoprawna wartość parametru ""Lokalizacja"": ""%1"".';
																			|tr = '""Konum"" parametresinin hatalı değeri: ""%1"".'"), String(Placement));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	SelectAndClose();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtClient
Procedure SelectAndClose()
	SelectionResult = New Structure;
	SelectionResult.Insert("GroupTitle", GroupTitle);
	SelectionResult.Insert("Placement", DataCompositionFieldPlacement[GroupPlacement]);
	NotifyChoice(SelectionResult);
	If IsOpen() Then
		Close(SelectionResult);
	EndIf;
EndProcedure

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("PrintObjects") Then
		PrintObjects.LoadValues(Parameters.PrintObjects);
	Else
		
		ExceptionText = NStr("vi = 'Giá trị cho tham số ""%1"" không được điền';
							|ru = 'Не заполнено значение параметра ""%1""';
							|en = 'Value is required for parameter ""%1""'; fa = 'Value is required for parameter ""%1""';
							|it = 'Il valore del parametro ""%1"" non è compilato';
							|pl = 'Nie wypełniono wartości parametru ""%1""';
							|tr = '""%1"" parametresi değeri doldurulmadı'");

		ExceptionText = StrTemplate(ExceptionText, "PrintObjects");
		Raise ExceptionText;
	EndIf;
	
	UploadFormSettings();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PrintAdjacentStagesOnChange(Item)
	
	WhenChangingParameters();
	
EndProcedure

&AtClient
Procedure PrintMaterialsOnChange(Item)
	
	WhenChangingParameters();
	
EndProcedure

&AtClient
Procedure PrintOutputItemsOnChange(Item)
	
	WhenChangingParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	
	PrintManagementClient.ExecutePrintCommand(
		"Document.ProductionStage2_2",
		"ProductionBatchMaintenanceSheet",
		PrintObjects.UnloadValues(),
		FormOwner,
		PrintParameterValues());
	
	Close();
	
EndProcedure

&AtClient
Procedure SetAllParameters(Command)
	
	FillParameters_(True);
	
EndProcedure

&AtClient
Procedure RemoveAllParameters(Command)
	
	FillParameters_(False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		Undefined,
		Settings);
	
EndProcedure
	
&AtClientAtServerNoContext
Function FormKey()
	
	Return "Document.ProductionStage2_2.PrintAccompanyingSheetForProductionLot";
	
EndFunction

&AtClient
Procedure WhenChangingParameters()
	
	Settings = PrintParameterValues();
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtClient
Procedure FillParameters_(Value)
	
	PrintParameters = ArrayOfPrintParameters();
	
	For Each Parameter In PrintParameters Do
		
		ThisObject[Parameter] = Value;
		
	EndDo;
	
	WhenChangingParameters();
	
EndProcedure

&AtClient
Function ArrayOfPrintParameters()
	
	Result = New Array;
	
	Result.Add("PrintAdjacentStages");
	Result.Add("PrintMaterials");
	Result.Add("PrintOutputItems");
	
	Return Result;
	
EndFunction

&AtClient
Function PrintParameterValues()
	
	PrintParameters = ArrayOfPrintParameters();
	
	Result = New Structure;
	
	For Each Parameter In PrintParameters Do
		
		Result.Insert(Parameter, ThisObject[Parameter]);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion


#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ListOfUsedRegisters.LoadValues(Parameters.ListOfUsedRegisters.UnloadValues());
	For Each Register In Metadata.Documents.RegisterAdjustment.RegisterRecords Do

		If Metadata.AccumulationRegisters.Contains(Register) Then

			Check = ListOfUsedRegisters.FindByValue(Register.Name) <> Undefined;
			AccumulationRegisterList.Add(Register.Name, Register.Synonym, Check);

		EndIf;

	EndDo;

	AccumulationRegisterList.SortByValue(SortDirection.Asc);

	For Each Register In Metadata.Documents.RegisterAdjustment.RegisterRecords Do

		If Metadata.InformationRegisters.Contains(Register) Then

			Check = ListOfUsedRegisters.FindByValue(Register.Name) <> Undefined;
			InformationRegisterList.Add(Register.Name, Register.Synonym, Check);

		EndIf;

	EndDo;

	InformationRegisterList.SortByValue(SortDirection.Asc);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UpdatePageTitle(PageTitleAccumulationRegisters, AccumulationRegisterList);

	UpdatePageTitle(TitleOfTheInformationRegistersPage, InformationRegisterList);

EndProcedure

#Region OtherProcedures

&AtClient
Procedure UpdatePageTitle(HeaderDetails_, RegistersList)

	HeaderDetails_ = String(GetNumberOfTagged(RegistersList)) + "/" + String(RegistersList.Count());

EndProcedure

&AtClient
Procedure CreateListOfRegistersToAdjust(ResultList, RegistersList)

	For Each Item In RegistersList Do

		RegisterUsed = ListOfUsedRegisters.FindByValue(Item.Value) <> Undefined;
		// It is necessary to disable the register.
		If Item.Check And Not RegisterUsed Then

			ResultList.Add(Item.Value, Item.Presentation, True);

		// You need to add a register.
		ElsIf Not Item.Check And RegisterUsed Then

			ResultList.Add(Item.Value, Item.Presentation, False);

		EndIf;
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Function GetNumberOfTagged(ValueList)

	Result = 0;
	For Each Item In ValueList Do
		If Item.Check Then
			Result = Result + 1;
		EndIf;
	EndDo;

	Return Result;

EndFunction

#EndRegion

#Region CommandHandlers

&AtClient
Procedure OK(Command)

	Result = New ValueList;

	CreateListOfRegistersToAdjust(Result, AccumulationRegisterList);
	CreateListOfRegistersToAdjust(Result, InformationRegisterList);

	Close(Result);

EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

&AtClient
Procedure AccumulationRegisterListOnChange(Item)

	UpdatePageTitle(PageTitleAccumulationRegisters, AccumulationRegisterList);

EndProcedure

&AtClient
Procedure InformationRegisterListOnChange(Item)

	UpdatePageTitle(TitleOfTheInformationRegistersPage, InformationRegisterList);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion


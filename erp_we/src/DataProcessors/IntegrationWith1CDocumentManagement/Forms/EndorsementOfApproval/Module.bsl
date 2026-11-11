#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters["Description"];
	ID = Parameters.ID;
	Type = Parameters.Type;
	
	Contributed = Parameters.Contributed;
	ContributedType = Parameters.ContributedType;
	ContributedID = Parameters.ContributedID;
	
	ApprovingPerson = Parameters.ApprovingPerson;
	ApprovingPersonType = Parameters.ApprovingPersonType;
	ApprovingPersonID = Parameters.ApprovingPersonID;
	
	If ValueIsFilled(ContributedID)
		And ApprovingPersonID <> ContributedID Then
		Items.ApprovingPerson.ToolTip =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã nhập: %1';
					|ru = 'Внес: %1';
					|en = 'Deposited by: %1'; fa = 'Deposited by: %1';
					|it = 'Introdotto: %1';
					|pl = 'Wprowadził: %1';
					|tr = 'Girildi: %1'"),
				Contributed);
	EndIf;
	
	Result = Parameters.Result;
	ResultType = Parameters.ResultType;
	ResultID = Parameters.ResultID;
	
	Date = Parameters.Date;
	Comment = Parameters.Comment;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion

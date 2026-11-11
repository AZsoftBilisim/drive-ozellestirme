&AtServer
&After("OnCreateAtServer")
Procedure sh_ListOnCreateAtServer(Cancel, StandardProcessing)
	If Items.Find("sh_ListShamsiDate") <> Undefined Then
		Return;
	EndIf;
	Column = Items.Add("sh_ListShamsiDate", Type("FormField"), Items.List);
	Column.Type     = FormFieldType.InputField;
	Column.DataPath = "List.shamsidate";
	Column.Title    = NStr("en = 'Shamsi date'; fa = 'تاریخ شمسی'");
EndProcedure                                      

&AtServerNoContext
Procedure sh_ListOnGetDataAtServer(ItemName, Settings, Rows)
	For Each Row In Rows Do
		Data = Row.Value.Data;
		If Data.Property("shamsidate") And Data.Property("Date") Then
			Data.shamsidate = sh_ShamsiCalendar.GregorianToShamsi(Data.Date);
		EndIf;
	EndDo;
EndProcedure
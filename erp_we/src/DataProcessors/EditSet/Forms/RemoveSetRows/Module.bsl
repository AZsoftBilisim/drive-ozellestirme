
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	NumberOfSets = Parameters.Sets.Count();

	Message = "";
	If NumberOfSets <= 1 Then
		Items.RemoveAllSetLines.Title = NStr("vi = 'Xóa bỏ tất cả dòng của tập hợp';
											|ru = 'Удалить все строки набора';
											|en = 'Remove all lines in set'; fa = 'Remove all lines in set';
											|it = 'Eliminare tutte le righe del set';
											|pl = 'Usunąć wszystkie wiersze zestawu';
											|tr = 'Kümenin tüm satırlarını sil'");
		Message = NStr("ru = 'Удаляемые строки входят в набор';
						|vi = 'Removed lines are included in the set';
						|en = 'Removed lines are included in the set'; fa = 'Removed lines are included in the set';
						|it = 'Removed lines are included in the set';
						|pl = 'Removed lines are included in the set';
						|tr = 'Silinen satırlar kümeye dahildir'");
	Else
		Items.RemoveAllSetLines.Title = NStr("vi = 'Xóa bỏ tất cả dòng của tập hợp';
											|ru = 'Удалить все строки наборов';
											|en = 'Remove all set lines'; fa = 'حذف همه سطرهای مجموعه';
											|it = 'Elimina tutte le righe dei set';
											|pl = 'Usuń wszystkie wiersze zestawów';
											|tr = 'Kümelerin tüm satırlarını sil'");
		Message = NStr("ru = 'Удаляемые строки входят в наборы';
						|vi = 'Removed lines are included in the sets';
						|en = 'Removed lines are included in the sets'; fa = 'Removed lines are included in the sets';
						|it = 'Removed lines are included in the sets';
						|pl = 'Removed lines are included in the sets';
						|tr = 'Silinen satırlar kümelere dahildir'");
	EndIf;
	
	If Parameters.Other.Count() > 0 Then
		Items.EditSet.Visible = False;
		If NumberOfSets <= 1 Then
			Message = NStr("ru = 'Некоторые из удаляемых строк входят в состав набора';
							|vi = 'Some of the removed lines are included in the set';
							|en = 'Some of the removed lines are included in the set'; fa = 'Some of the removed lines are included in the set';
							|it = 'Some of the removed lines are included in the set';
							|pl = 'Some of the removed lines are included in the set';
							|tr = 'Silinecek satırlardan bazıları set kapsamına dahildir'");
		Else
			Message = NStr("ru = 'Некоторые из удаляемых строк входят в состав наборов';
							|vi = 'Some of the removed lines are included in the sets';
							|en = 'Some of the removed lines are included in the sets'; fa = 'Some of the removed lines are included in the sets';
							|it = 'Some of the removed lines are included in the sets';
							|pl = 'Some of the removed lines are included in the sets';
							|tr = 'Silinecek satırlardan bazıları kümelerin içeriğine dahildir'");
		EndIf;
	EndIf;
	
	If Parameters.Copy Then
		Items.EditSet.Visible = True;
		Items.RemoveAllSetLines.Visible = False;
		If NumberOfSets <= 1 Then
			Message = NStr("ru = 'Выделенная строка входит в набор';
							|vi = 'The selected line is in the set';
							|en = 'The selected line is in the set'; fa = 'The selected line is in the set';
							|it = 'The selected line is in the set';
							|pl = 'The selected line is in the set';
							|tr = 'Seçilen satır kümeye dahildir'");
		Else
			Message = NStr("ru = 'Выделенные строки входят в наборы';
							|vi = 'The selected lines are in the sets';
							|en = 'The selected lines are in the sets'; fa = 'The selected lines are in the sets';
							|it = 'The selected lines are in the sets';
							|pl = 'The selected lines are in the sets';
							|tr = 'Seçilen satırlar kümelere dahildir'");
		EndIf;
	EndIf;

	If IsBlankString(Message) Then
		Items.MessageSets.TitleLocation = FormItemTitleLocation.None;
	Else
		Items.MessageSets.Title = Message;
	EndIf;

	If NumberOfSets > 1 Then
		Items.EditSet.Visible = False;
	EndIf;
	
	RepresentationsOfSets = New Array;
	LimitingSets = 0;
	For Each SetRow In Parameters.Sets Do
		RepresentationsOfSets.Add(ProductsClientServer.ProductPresentation(SetRow.ProductsInSet,
			SetRow.ItemVariantOfSet));
		LimitingSets = LimitingSets + 1;
		If LimitingSets = 5 Then
			Break;
		EndIf;
	EndDo;
	If NumberOfSets > LimitingSets Then
		SetsOver = NStr("ru = 'и другие наборы. Всего: %1';
						|vi = 'and other sets. Total: %1';
						|en = 'and other sets. Total: %1'; fa = 'and other sets. Total: %1';
						|it = 'and other sets. Total: %1';
						|pl = 'and other sets. Total: %1';
						|tr = 've diğer kümeler. Toplam: %1'");
		RepresentationsOfSets.Add(StrTemplate(SetsOver, Format(NumberOfSets, "NG=")));
		LimitingSets = LimitingSets + 1;
	EndIf;
	MessageSets = StrConcat(RepresentationsOfSets, Chars.LF);
	Items.MessageSets.Height = Min(NumberOfSets, LimitingSets);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditSet(Command)
	Close("EditSet");
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close("Cancel");
EndProcedure

&AtClient
Procedure DeleteAllRows(Command)
	Close("DeleteEntireSet");
EndProcedure

#EndRegion

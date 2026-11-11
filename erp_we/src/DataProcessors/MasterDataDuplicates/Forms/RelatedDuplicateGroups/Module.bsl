#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each Source In Parameters.SourcesAndDuplicates Do
		
		FirstLevelRow = Tree.GetItems().Add();
		
		SecondLevelStrings = FirstLevelRow.GetItems();
		Sources = Source.Value; // Array of Structure
		For Each Duplicate1 In Sources Do
			FillPropertyValues(SecondLevelStrings.Add(), Duplicate1, , "Source");
		EndDo;
		
		FirstLevelRow.Source = ?(
			Duplicate1.Source <> Undefined,
			Duplicate1.Source, 
			NStr("vi = 'Đã xác nhận bản trùng lặp';
				|ru = 'Дубли подтверждены';
				|en = 'Duplicates are confirmed'; fa = 'Duplicates are confirmed';
				|it = 'Duplicates are confirmed';
				|pl = 'Duplicates are confirmed';
				|tr = 'Yinelenen öğeler onaylandı'"));
		
	EndDo;
	
EndProcedure

#EndRegion

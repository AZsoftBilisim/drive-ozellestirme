
#Region FormCommandsEventHandlers

&AtClient
Procedure ExecutePerformerReplacement(Command)

	Cancel = False;
	If Not CheckFilling() Then
		Cancel = True;
	ElsIf CurrentPerformer = NewArtist Then
		CommonClient.MessageToUser(NStr("vi = 'Người thực hiện hiện tại và người thực hiện mới giống nhau.';
										|ru = 'Текущий и новый исполнители не отличаются.';
										|en = 'The current assignee and the new assignee are the same.'; fa = 'The current assignee and the new assignee are the same.';
										|it = 'Текущий и новый исполнители не отличаются.';
										|pl = 'The current assignee and the new assignee are the same.';
										|tr = 'Mevcut ve yeni atananlar arasında fark yok.'"), , , ,
			Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	StructureOfPerformers = New Structure;
	StructureOfPerformers.Insert("CurrentPerformer", CurrentPerformer);
	StructureOfPerformers.Insert("NewArtist", NewArtist);
	
	Close(StructureOfPerformers);

EndProcedure

#EndRegion
#Region Public

// Checks whether the details required for copying are complete
//
// Parameters:
//	CurrentRow - FormDataCollectionItem  - Element of the table part to check for fullness.
//
// Returns:
//	Boolean - False if the required data is not filled in.
//
Function CopyingLinesIsPossible(CurrentRow) Export
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Để thực hiện lệnh cần chọn dòng phần bảng.';
							|ru = 'Для выполнения команды требуется выбрать строку табличной части.';
							|en = 'To execute the command, select a table row.'; fa = 'To execute the command, select a table row.';
							|it = 'Per eseguire il comando, è necessario selezionare una riga della parte tabulare.';
							|pl = 'W celu wykonania polecenia należy wybrać wiersz części tabelarycznej.';
							|tr = 'Komutu yürütmek için tablo bölümünde bir satır seçilmesi gerekir.'");
		ShowMessageBox(,MessageText);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Invoked in the forms of documents and directories when you copy lines.
// 
// Parameters:
//     NumberOfAllocated - Number - the number of selected rows in the table part.
//
Procedure NotifyUserAboutCopyingStrings(NumberOfAllocated) Export
	
	MessageText = NStr("vi = 'Đã sao chép các dòng vào bộ đệm trao đổi (%NumberOfAllocated%)';
						|ru = 'В буфер обмена скопировано строк (%NumberOfAllocated%)';
						|en = '(%NumberOfAllocated%) lines are copied to the clipboard'; fa = '(%NumberOfAllocated%) lines are copied to the clipboard';
						|it = 'Negli Appunti vengono copiate le righe (%NumberOfAllocated%)';
						|pl = 'Do buferu wymiany zostało skopiowano wierszy (%NumberOfAllocated%)';
						|tr = 'Satır panoya kopyalandı (%NumberOfAllocated%)'");
	MessageText = StrReplace(MessageText, "%NumberOfAllocated%", NumberOfAllocated);
	
	TitleText = NStr("vi = 'Đã sao chép dòng';
					|ru = 'Строки скопированы';
					|en = 'Lines are copied'; fa = 'Lines are copied';
					|it = 'Righe copiate';
					|pl = 'Wiersze są skopiowane';
					|tr = 'Satırlar kopyalandı'");
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	Notify("CopyingLinesToClipboard");
	
EndProcedure

// Invoked in the forms of documents and directories when you insert rows.
// 
// Parameters:
//     NumberOfInserted - Number - the number of rows inserted in the table part.
//
Procedure NotifyUserAboutInsertingRows(NumberOfInserted) Export
	
	MessageText = NStr("vi = 'Từ bộ đệm trao đổi đã chèn dòng (%NumberOfInserted%)';
						|ru = 'Из буфера обмена вставлено строк (%NumberOfInserted%)';
						|en = '(%NumberOfInserted%) lines are inserted from the clipboard'; fa = '(%NumberOfInserted%) lines are inserted from the clipboard';
						|it = 'Negli Appunti vengono inserite le righe (%NumberOfInserted%)';
						|pl = 'Z buferu wymiany są wstawione wierszy (%NumberOfInserted%)';
						|tr = 'Satır panodan eklendi (%NumberOfInserted%)'");
	MessageText = StrReplace(MessageText, "%NumberOfInserted%", NumberOfInserted);
	
	TitleText = NStr("vi = 'Đã chèn dòng';
					|ru = 'Строки вставлены';
					|en = 'Lines are inserted'; fa = 'Lines are inserted';
					|it = 'Righe inserite';
					|pl = 'Wiersze są wstawione';
					|tr = 'Satırlar eklendi'");
	ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
	
EndProcedure

#EndRegion

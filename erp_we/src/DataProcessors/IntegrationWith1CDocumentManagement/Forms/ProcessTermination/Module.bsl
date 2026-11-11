#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MessageText = NStr(
		"vi = 'Sẽ ngắt quy trình và các nhiệm vụ chưa thực hiện trong quy trình.
		|Trạng thái các chứng từ do quy trình này thiết lập sẽ bị xóa.
		|
		|Chú ý! Tất cả những thay đổi đã nhập sẽ không thể phục hồi.';
		|ru = 'Будет выполнено прерывание процесса и его невыполненных задач.
		|Состояния документов, установленные этим процессом, будут очищены.
		|
		|Внимание! Все внесенные изменения будут необратимыми.';
		|en = 'The process and all its unfinished tasks will be aborted.
		|Document states set by this process will be cleared.
		|
		|Warning! Any changes you made cannot be undone.'; fa = 'The process and all its unfinished tasks will be aborted.
		|Document states set by this process will be cleared.
		|
		|Warning! Any changes you made cannot be undone.';
		|it = 'Sarà eseguita una interruzione del processo e dei suoi compiti non completati.
		|Gli stati dei documenti, impostati da parte di questo processo, saranno cancellati.
		|
		|Attenzione! Tutte le modifiche apportate saranno permanenti.';
		|pl = 'Zostanie wykonane przerywanie procesu i jego nie wykonanych zadań.
		|Statusy dokumentów, ustawione przez ten proces, zostaną wyczyszczone.
		|
		|Uwaga! Wszystkie wprowadzone zmiany będą nieodwracalne.';
		|tr = 'Süreç ve bekleyen görevleri kesintiye uğrayacak.
		|Bu işlem tarafından ayarlanan belge durumları temizlenecektir.
		|
		|Dikkat! Yapılan tüm değişiklikler geri alınamaz olacaktır.'");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InterruptProcess(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(False);
	
EndProcedure

#EndRegion
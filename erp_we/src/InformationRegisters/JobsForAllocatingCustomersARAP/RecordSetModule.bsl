#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Procedure BeforeWrite(Cancel, Replacing)
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined
		And Count() > 0 Then
		Cancel = True;
		Raise 
			NStr("vi = 'Chỉ nên thực hiện thay đổi biểu ghi ""Nhiệm vụ cần phân bổ hạch toán với khách hàng"" ở nút chính CSTTPT.
			           |Sau đó tiến hành đồng bộ với các nút trực thuộc.';
			           |ru = 'Изменение регистра ""Задания к распределению расчетов с клиентами"" следует выполнять только в главном узле РИБ.
			           |Затем выполнить синхронизацию с подчиненными узлами.';
			           |en = 'Change the ""Jobs for allocating customer AR/AP"" register only in the master node of the distributed infobase.
			           |Then synchronize with subordinate nodes.'; fa = 'Change the ""Jobs for allocating customer AR/AP"" register only in the master node of the distributed infobase.
			           |Then synchronize with subordinate nodes.';
			           |it = 'È necessario eseguire la modifica del registro ""Compiti di distribuzione dei calcoli con i clienti"" solo nel nodo RIB principale.
			           |Poi eseguire la sincronizzazione con i nodi subordinati.';
			           |pl = 'Zmianę rejestru ""Zadania do podziału rozliczeń z nabywcami"" należy wykonać tylko w głównym węźle rozproszonej bazy informacyjnej.
			           |Następnie wykonać synchronizację z podporządkowanymi węzłami.';
			           |tr = '""İstemci mutabakat dağıtım görevleri"" kaydının değiştirilmesi yalnızca ana DBT düğümünde gerçekleştirilmelidir.
			           |Ardından bağımlı düğümlerle senkronizasyon gerçekleştir.'");
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
EndProcedure

#EndRegion

#EndIf
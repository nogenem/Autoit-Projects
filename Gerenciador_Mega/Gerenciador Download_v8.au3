#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icon\_mega.co.nz.ico
#AutoIt3Wrapper_Outfile=Mega_Down.Exe
#AutoIt3Wrapper_Compression=4
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstants.au3>
#include <Array.au3>
#Include <FF.au3>

HotKeySet("{F11}", "sair")

#Region ### Download Form ###
$formDownload = GUICreate("Download", 625, 283, 260, 183)
$ListViewDown = GUICtrlCreateListView("N°|Link|Status", 16, 16, 594, 214) ;16 24
GUICtrlSendMsg(-1, 0x101E, 0, 30)
GUICtrlSendMsg(-1, 0x101E, 1, 470)
GUICtrlSendMsg(-1, 0x101E, 2, 90)
$btnVoltar = GUICtrlCreateButton("Voltar", 272, 248, 75, 25, 0)
$lblSair = GUICtrlCreateLabel("Para sair aperte F11", 488, 0, 125, 19)
GUICtrlSetFont(-1, 10, 400, 0, "Britannic Bold")
#EndRegion

#Region ### Get Links Form ###
$formGetLinks = GUICreate("Gerenciador de Downlods", 402, 249, 365, 185)
$editGetLinks = GUICtrlCreateEdit("", 16, 40, 369, 153)
$lblGetLinks = GUICtrlCreateLabel("Informe os links para downlod:", 16, 16, 218, 24)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
$btnDown = GUICtrlCreateButton("Downlod", 160, 208, 75, 25, 0)
#EndRegion

#Region ### Variaveis do programa ###
Global $links 				;tabela que vai guardar os links
Global $itensView			;tabela com os itens da listView
Global $nDowns 		= 0 	;registrador do numero de downloads ja feitos
Global $qntRetry	= 0		;qnts links ja foram pra lista de retry
Global $maxRetry 	= 10	;numero maximo de retrys
#EndRegion

; https://mega.co.nz/#!QNQVlbJb!MzrXoXAeoOyMomAw6_BuJytA7GlwzkhSqHGyobskvQ8 [testes]
; https://mega.co.nz/#!YMlFgCaD!PhGxNmDSSYMon4Nf2SglKlI6hBlus1LsQMKZJLuFzbo [testes]

#Region ### Main ###
showGetLinks()

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			sair()
		Case $btnDown
			beginDownload()
		Case $btnVoltar
			showGetLinks()
	EndSwitch
WEnd
#EndRegion

Func Download()
	_FFStart()
	_FFAction("Min")

	IF _FFIsConnected() Then
		_Download()
	Else
		MsgBox(0, "Error", "Ocorreu um erro ao iniciar o download, por favor, volte a janela de links.")
	EndIf

	_FFQuit()
EndFunc

Func _Download()
	If UBound($links) == $nDowns Then
		endDownloads()
		Return
	EndIf

	Local $Erro		= False		;variavel para erro
	Local $Value	= ""		;valores dos _FFObj

	Sleep(1000)
	_FFOpenURL($links[$nDowns])
	$nDowns += 1
	GUICtrlSetData($itensView[$nDowns-1], "||Iniciando")

	Sleep(2000)
	_ClickButton() ;clica no botao de download
	Sleep(2000)

	Do
		_FFXpath("//div[@class='downloading-txt temporary-error']/child::text()") ;ve se deu temporary error

		$Value = _FFObj("xpath.nodeValue")
		If $Value <> "" Then
			If $qntRetry < $maxRetry Then
				_ArrayAdd($links, $links[$nDowns-1])
				GUICtrlSetData($itensView[$nDowns-1], "||Retry")
				$qntRetry += 1
			EndIf
			$Erro = True
		EndIf
		_FFXpath("//div[@class='new-download-icon']/div[1]/child::text()") ;pega a % do download
		$Value = _FFObj("xpath.nodeValue")
	Until $Erro Or ($Value <> "" And $Value <> "_FFCmd_Err")

	If Not $Erro Then
		Do
			_FFXpath("//div[@class='new-download-icon']/div[1]/child::text()") ;pega a % do download
			$Value = _FFObj("xpath.nodeValue")
			GUICtrlSetData($itensView[$nDowns-1], StringFormat("||%s%", $Value))
			Sleep(3000)
		Until $Value == "100"
		GUICtrlSetData($itensView[$nDowns-1], "||Done")
	EndIf

	_Download()
EndFunc

Func _ClickButton() ;click no botao de download
	Local $value = ""
	While 1
		Sleep(500)
		$value = _FFCmd(".getElementsByClassName('new-download-buttons')[0].offsetParent") ;ve se a div dos botoes esta visivel

		If $value <> "_FFCmd_Err" And $value <> "" Then
			Local $btn = _FFXpath("//div[@class='new-download-button-txt2']") ;pega o botao de down
			_FFClick($btn)
			ExitLoop
		EndIf
	WEnd
EndFunc

;Nao utilizada
Func _OpenURL() ;abre a url do down
	Local 	$url1 = $links[$nDowns]
			$url1 = StringRegExp($url1, "#(.*)", 3)
	Local 	$url2

	While 1
		_FFOpenURL($links[$nDowns])
		Sleep(500)

		$url2 = _FFCmd(".URL") ;pega a url q ta no navegador
		If Not @error Then
			$url2 = StringRegExp($url2, "#(.*)", 3)
			If $url1[0] = $url2[0] Then
				$nDowns += 1
				ExitLoop
			EndIf
		EndIf
	WEnd
EndFunc

Func endDownloads()
	MsgBox(0, "Done", StringFormat("Downloads terminados! [Retrys: %d]", $qntRetry))
	GUICtrlSetData($editGetLinks, "")
	$nDowns 	= 0
	$qntRetry 	= 0
EndFunc

Func addLinksToListView()
	If not IsArray($itensView) Then
		Dim $itensView[UBound($links)]

		For $i = 0 To UBound($links)-1
			$itensView[$i] = GUICtrlCreateListViewItem(StringFormat("%d|%s|Não Iniciado", ($i+1), $links[$i]), $ListViewDown)
		Next
	Else
		For $i = 0 To UBound($itensView)-1
			GUICtrlDelete($itensView[$i])
		Next
		$itensView = ""
		addLinksToListView()
	EndIf
EndFunc

Func linksAreValid()
	For $i = 0 To UBound($links)-1
		If Not StringRegExp($links[$i], "(http|https)://mega.co.nz/(.*)") Then ;verifica se eh um link do Mega
			Return False
		EndIf
	Next
	Return True
EndFunc

Func beginDownload()
	$links = GUICtrlRead($editGetLinks)
	$links = StringRegExp($links, "[^\s\n]+", 3)
	If not IsArray($links) Or Not linksAreValid() Then
		MsgBox(0, "Error", "Ocorreu um erro com os links fornecidos, verifique eles e clique em Download denovo.")
	Else
		showDownload()
		addLinksToListView()
		Download()
	EndIf
EndFunc

Func showDownload()
	GUISetState(@SW_HIDE, $formGetLinks)
	GUISetState(@SW_SHOW, $formDownload)
EndFunc

Func showGetLinks()
	GUISetState(@SW_HIDE, $formDownload)
	GUISetState(@SW_SHOW, $formGetLinks)
EndFunc

Func sair()
	IF _FFIsConnected_2() Then
		_FFDisConnect()
	EndIf
	Exit
EndFunc

Func _Print($msg)
	ConsoleWrite(@CRLF & @CRLF & "Print: " & $msg & "." & @CRLF & @CRLF)
EndFunc
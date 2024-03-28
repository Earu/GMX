import * as vscode from "vscode";
import * as net from "net";
import * as path from "path";

function run(state: "menu" | "client") {
	let document = vscode.window.activeTextEditor?.document;
	if (!document) return;

	let title = path.basename(document.uri.fsPath);
	let gmodSocket = new net.Socket();
	gmodSocket.connect(27202);
	gmodSocket.write(`${state}\n${title}\n${document.getText()}`);
	gmodSocket.on("error", ex => vscode.window.showErrorMessage(ex.message));
	gmodSocket.end();
}

let vscodeSocket: net.Server;
export function activate(context: vscode.ExtensionContext) {
	let command = vscode.commands.registerCommand;

	context.subscriptions.push(
		command('gmx.runOnMenu', () => run("menu")),
		command('gmx.runOnClient', () => run("client")),
	);

	vscodeSocket = net.createServer(async client => {
		console.debug(client.address());

		let data = "";
		client.on("data", buff => {
			data += buff.toString();
		});

		client.on("close", async () => {
			try {
				let chunks = data.split("\n");
				let title = chunks[0];
				let code = chunks.slice(1).join("\n");

				let doc = await vscode.workspace.openTextDocument({
					content: code,
					language: "lua",
				});

				await vscode.window.showTextDocument(doc, { preserveFocus: false });

				let edit = new vscode.WorkspaceEdit();
				edit.renameFile(doc.uri, vscode.Uri.parse(title), { ignoreIfExists: true });
				await vscode.workspace.applyEdit(edit);

				await vscode.workspace.saveAll();
			} catch (err) {
				console.error(err);
			}
		});
	});

	vscodeSocket.listen(27203);
	vscodeSocket.on('error', (ex) => {
		if ((ex as any).code === 'EADDRINUSE') {
			console.log('Address in use, retrying...');
			setTimeout(() => {
				vscodeSocket.close();
				vscodeSocket.listen(27203);
			}, 1000);
		} else {
			vscode.window.showErrorMessage(ex.message)
		}
	});
}

export function deactivate() {
	if (!vscodeSocket) return;

	vscodeSocket.close();
}

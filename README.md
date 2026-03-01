# Disable Dia AI Auto-Routing

Force Dia’s address bar to **always route to web search** by patching the on-device ML classification head. This prevents automatic AI chat routing while still allowing manual AI selection.

## Background

I love Dia for its design and tab system. The reason why I used to use Chrome instead is because there is no way in Dia to disable the auto-router "feature" which decides whether your search should be sent to Google or the AI chat. 

As a professional user, I quickly open my browser, want to Google something, hit enter and ... the AI chat opens. You need to go copy your input, click on the search bar, paste the text and then make sure to click on "Google". I never even once wanted this AI chat to open up. And no way I am doing this every time. 

So I reversed engineered Dia's binary and found a way to modify the bias so the AI route is mathematically impossible. I can still manually select the AI chat, but if I don't do that, I can finally hit enter and just get Google. 

---

## What This Does

Dia uses an on-device classifier to decide whether your input should:
- Go to web search
- Open the AI chat (“Supertab”)

This project modifies the classifier bias stored in:

`~/Library/Caches/company.thebrowser.dia/ModelFileCache/ondevicerouter/classification_head.safetensors`

By setting the AI class bias to a very large negative value, the model will always predict **web search**.

The file is then locked (read-only) so Dia cannot overwrite it on startup.

No binary patching or code-signing changes. 

---

## How It Works 

The routing model contains a 2-class head:

`[ web_search_logit , ai_chat_logit ]`

We set

`bias[1] = -1000.0`

This makes the AI class logit effectively impossible to win after softmax.

The router logic remains untouched, it simply never selects AI automatically.

---

## Included Scripts

### patch_dia_router.sh

- Creates a Python virtual environment (if missing)
- Installs required dependencies (torch, safetensors, numpy, packaging)
- Patches the classification head bias
- Locks the file (chmod 444)

### unlock_dia_router.sh

- Removes the read-only lock (chmod 644)
- Allows Dia to regenerate or overwrite the model

---

## Setup

Place both scripts in the same directory (for example, your home folder).

### Make Scripts Executable (macOS)

```
chmod +x patch_dia_router.sh
chmod +x unlock_dia_router.sh
```

## Usage

1. Quit Dia
2. Apply Patch using ./patch_dia_router.sh
3. Open Dia

## Undo Patch

If you want to restore default behavior:

`./unlock_dia_router.sh`

## After Dia Updates

If an update resets routing behavior:

1. Quit Dia
2. Run:

`./patch_dia_router.sh`


---

## Background Information

I have never worked with binary files before, so I used Claude Code to reverse engineer Dia. It ran for 1,5h straight and (with a bit of guidance) managed to create a very detailed report. Through this we (luckily) found a way to get the desired effect without strong binary patching, but iwth model-layer intervention instead. 

classification_head.safetensors contains multiple tensors: 

- classifier.modules_to_save.default.weight — [2, 768]
- classifier.modules_to_save.default.bias — [2]
- classifier.original_module.weight — [2, 768]
- classifier.original_module.bias — [2]

The bias values before the patch were

```
modules_to_save bias: [ 0.0041, -0.0041 ]
original_module bias: [ 0.0, 0.0 ]
```

with index 0 being web search, index 1 AI chat. So the patch sets `bias[1] = -1000.0`. Both modules_to_save and original_module biases are modified to avoid ambiguity in LoRA/base merging. We lock the file using `chmod 444 classification_head.safetensors`.

### Routing stack

```
Search Bar
   ↓
OnDeviceRouter
   ↓
DistilBERT + LoRA adapter
   ↓
classification_head (2-class)
   ↓
CommandBarResult enum
   ↓
UI routing (webSearch vs supertab)
```
defmodule EmailSorter.MLProvider do
  @callback load_model({:hf, String.t()}) :: {:ok, map()} | {:error, any()}
  @callback load_tokenizer({:hf, String.t()}) :: {:ok, map()} | {:error, any()}
  @callback text_classification(map(), map(), keyword()) :: map()
end

defmodule EmailSorter.BumblebeeProvider do
  @behaviour EmailSorter.MLProvider

  @impl true
  def load_model(model_info) do
    Bumblebee.load_model(model_info)
  end

  @impl true
  def load_tokenizer(model_info) do
    Bumblebee.load_tokenizer(model_info)
  end

  @impl true
  def text_classification(model, tokenizer, opts) do
    Bumblebee.Text.text_classification(model, tokenizer, opts)
  end
end
